#!/bin/bash

set -e

# 사용자 정의 변수 입력
CLUSTER_NAME="eks-demo"
AWS_REGION="ap-northeast-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# OIDC Provider 연결 확인 및 생성
echo "Checking OIDC provider for cluster: $CLUSTER_NAME..."
OIDC_URL=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(echo $OIDC_URL | awk -F '/id/' '{print $2}')

if aws iam list-open-id-connect-providers | grep -q \$OIDC_ID; then
    echo "OIDC provider already exists."
else
    echo "Associating OIDC provider..."
    eksctl utils associate-iam-oidc-provider --region ${AWS_REGION} --cluster ${CLUSTER_NAME} --approve
fi

# IAM Policy 다운로드 및 생성
echo "📥 Downloading IAM policy for AWS Load Balancer Controller..."
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

echo "🔐 Creating IAM policy..."
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    || echo "Policy might already exist."

# IAM ServiceAccount 생성 여부 확인 후 생성
if ! eksctl get iamserviceaccount --cluster ${CLUSTER_NAME} --name aws-load-balancer-controller --namespace kube-system | grep -q aws-load-balancer-controller; then
    echo "🔧 Creating IAM ServiceAccount for AWS Load Balancer Controller..."
    eksctl create iamserviceaccount \
        --cluster ${CLUSTER_NAME} \
        --namespace kube-system \
        --name aws-load-balancer-controller \
        --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
        --override-existing-serviceaccounts \
        --approve

else
    echo "IAM ServiceAccount already exists."
fi