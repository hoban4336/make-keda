#!/bin/bash
set -euo pipefail
IFS=$'\\n\\t'

### [1] 도구 설치
TOOL_INSTALL_SCRIPT="./tools.sh"
if [ ! -f "$TOOL_INSTALL_SCRIPT" ]; then
  echo "❌ 도구 설치 스크립트가 없습니다: $TOOL_INSTALL_SCRIPT"
  exit 1
fi

echo "🔧 도구 설치 시작..."
bash "$TOOL_INSTALL_SCRIPT"

### [2] 환경 변수 설정
export KARPENTER_NAMESPACE="kube-system"
export KARPENTER_VERSION="1.4.0"
export K8S_VERSION="1.32"
export AWS_PARTITION="aws"
export CLUSTER_NAME="eks-karpenter"
export AWS_DEFAULT_REGION="ap-northeast-2"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export TEMPOUT="karpenter-cfn.yaml"

### [3] ALIAS_VERSION 가져오기
export ALIAS_VERSION="$(aws ssm get-parameter \
  --name "/aws/service/eks/optimized-ami/${K8S_VERSION}/amazon-linux-2023/x86_64/standard/recommended/image_id" \
  --query Parameter.Value --output text | \
  xargs -I {} aws ec2 describe-images --image-ids {} \
  --query 'Images[0].Name' --output text | \
  sed -r 's/^.*(v[[:digit:]]+).*$/\\1/')"

# echo "🔍 최신 Ubuntu 20.04 AMI ID 조회 중..."
# export UBUNTU_AMI_ID=$(aws ec2 describe-images \\
#   --owners 099720109477 \\
#   --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" \\
#             "Name=virtualization-type,Values=hvm" \\
#             "Name=root-device-type,Values=ebs" \\
#   --query 'Images[*].[ImageId,CreationDate]' \\
#   --region ${AWS_DEFAULT_REGION} \\
#   --output text | sort -k2 -r | head -n 1 | cut -f1)

# echo "✅ Ubuntu AMI ID: $UBUNTU_AMI_ID"

### [4] CloudFormation IAM 리소스 생성
curl -fsSL "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${KARPENTER_VERSION}/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml" \
  -o "${TEMPOUT}"

aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}"

### [5] eksctl 클러스터 생성
if [ ! -f karpenter.yaml ]; then
  echo "❌ karpenter.yaml 파일이 필요합니다. 같은 디렉토리에 있어야 합니다."
  exit 1
fi

echo "📄 karpenter.yaml 생성 중..."
envsubst < karpenter.template > karpenter.yaml

echo "🚀 eksctl 클러스터 생성 시작..."
eksctl create cluster -f karpenter.yaml

### [6] Helm으로 Karpenter Controller 설치
helm registry logout public.ecr.aws

helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version "${KARPENTER_VERSION}" \
  --namespace "${KARPENTER_NAMESPACE}" --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set "settings.interruptionQueue=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi \
  --wait

### [7] Karpenter NodePool 및 NodeClass 정의
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${CLUSTER_NAME}
  securityGroupSelectorTerms:
    - tags:
        aws:eks:cluster-name: ${CLUSTER_NAME}
  tags:
    Name: karpenter-node
---
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: spot-pool
spec:
  template:
    metadata:
      labels:
        intent: apps
    spec:
      nodeClassRef:
        name: default
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenUnderutilized
EOF

### [8] 테스트 워크로드 배포
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
      containers:
      - name: inflate
        image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
        resources:
          requests:
            cpu: 1
        securityContext:
          allowPrivilegeEscalation: false
EOF

### [9] 워크로드 스케일링 & 로그 확인
kubectl scale deployment inflate --replicas 5
kubectl logs -f -n "${KARPENTER_NAMESPACE}" -l app.kubernetes.io/name=karpenter -c controller
