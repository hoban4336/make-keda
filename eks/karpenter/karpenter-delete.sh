#!/bin/bash
set -euo pipefail

export CLUSTER_NAME="eks-karpenter"
export AWS_DEFAULT_REGION="ap-northeast-2"

### [1] 테스트 워크로드 및 karpenter 리소스 삭제
echo "🗑️ 테스트 워크로드 및 Karpenter CRD 삭제..."

# Delete deployment if exists
kubectl get deployment inflate &>/dev/null && kubectl delete deployment inflate || echo "✅ inflate deployment 없음"

# Delete nodepool if CRD exists
if kubectl get crd nodepools.karpenter.sh &>/dev/null; then
  kubectl delete nodepool spot-pool --ignore-not-found
else
  echo "✅ NodePool CRD 없음"
fi

# Delete ec2nodeclass if CRD exists
if kubectl get crd ec2nodeclasses.karpenter.k8s.aws &>/dev/null; then
  kubectl delete ec2nodeclass default --ignore-not-found
else
  echo "✅ EC2NodeClass CRD 없음"
fi

### [2] Helm release 삭제
echo "🗑️ Helm으로 설치된 karpenter 삭제..."
helm uninstall karpenter -n kube-system || echo "✅ helm 릴리스 없음 또는 이미 제거됨"

### [3] CloudFormation IAM 리소스 스택 삭제
echo "🗑️ CloudFormation IAM 스택 삭제 중..."
aws cloudformation delete-stack --stack-name "Karpenter-${CLUSTER_NAME}"
aws cloudformation wait stack-delete-complete --stack-name "Karpenter-${CLUSTER_NAME}"

### [4] eksctl 클러스터 삭제
echo "🗑️ eksctl 클러스터 삭제 중..."
eksctl delete cluster --name "${CLUSTER_NAME}" --region "${AWS_DEFAULT_REGION}"
echo "✅ 삭제 완료"