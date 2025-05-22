
# eksctl
- VPC/Subnet/IGW 등을 자동으로 생성합니다.

```bash
eksctl create cluster -f eks/eks-demo-cluster.yaml

2025-05-18 20:27:57 [ℹ]  eksctl version 0.208.0
2025-05-18 20:27:57 [ℹ]  using region ap-northeast-2
2025-05-18 20:27:57 [!]  Amazon EKS will no longer publish EKS-optimized Amazon Linux 2 (AL2) AMIs after November 26th, 2025. Additionally, Kubernetes version 1.32 is the last version for which Amazon EKS will release AL2 AMIs. From version 1.33 onwards, Amazon EKS will continue to release AL2023 and Bottlerocket based AMIs. The default AMI family when creating clusters and nodegroups in Eksctl will be changed to AL2023 in the future.
2025-05-18 20:27:58 [ℹ]  setting availability zones to [ap-northeast-2b ap-northeast-2a ap-northeast-2c]
2025-05-18 20:27:58 [ℹ]  subnets for ap-northeast-2b - public:10.0.0.0/19 private:10.0.96.0/19
2025-05-18 20:27:58 [ℹ]  subnets for ap-northeast-2a - public:10.0.32.0/19 private:10.0.128.0/19
2025-05-18 20:27:58 [ℹ]  subnets for ap-northeast-2c - public:10.0.64.0/19 private:10.0.160.0/19
2025-05-18 20:27:58 [ℹ]  nodegroup "node-group" will use "" [AmazonLinux2/1.27]
2025-05-18 20:27:58 [ℹ]  using Kubernetes version 1.27
2025-05-18 20:27:58 [ℹ]  creating EKS cluster "eks-demo" in "ap-northeast-2" region with managed nodes
2025-05-18 20:27:58 [ℹ]  1 nodegroup (node-group) was included (based on the include/exclude rules)
2025-05-18 20:27:58 [ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
2025-05-18 20:27:58 [ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=ap-northeast-2 --cluster=eks-demo'
2025-05-18 20:27:58 [ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "eks-demo" in "ap-northeast-2"
2025-05-18 20:27:58 [ℹ]  configuring CloudWatch logging for cluster "eks-demo" in "ap-northeast-2" (enabled types: api, audit, authenticator, controllerManager, scheduler & no types disabled)
2025-05-18 20:27:58 [ℹ]  default addons metrics-server, vpc-cni, kube-proxy, coredns were not specified, will install them as EKS addons
2025-05-18 20:27:58 [ℹ]
2 sequential tasks: { create cluster control plane "eks-demo",
    2 sequential sub-tasks: {
        5 sequential sub-tasks: {
            1 task: { create addons },
            wait for control plane to become ready,
            associate IAM OIDC provider,
            no tasks,
            update VPC CNI to use IRSA if required,
        },
        create managed nodegroup "node-group",
    }
}
2025-05-18 20:27:58 [ℹ]  building cluster stack "eksctl-eks-demo-cluster"
2025-05-18 20:27:58 [ℹ]  deploying stack "eksctl-eks-demo-cluster"
2025-05-18 20:28:28 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:28:58 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:29:58 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:30:58 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:31:58 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:32:59 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:33:59 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:34:59 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-cluster"
2025-05-18 20:35:01 [ℹ]  creating addon: metrics-server
2025-05-18 20:35:01 [ℹ]  successfully created addon: metrics-server
2025-05-18 20:35:02 [!]  recommended policies were found for "vpc-cni" addon, but since OIDC is disabled on the cluster, eksctl cannot configure the requested permissions; the recommended way to provide IAM permissions for "vpc-cni" addon is via pod identity associations; after addon creation is completed, add all recommended policies to the config file, under `addon.PodIdentityAssociations`, and run `eksctl update addon`
2025-05-18 20:35:02 [ℹ]  creating addon: vpc-cni
2025-05-18 20:35:02 [ℹ]  successfully created addon: vpc-cni
2025-05-18 20:35:02 [ℹ]  creating addon: kube-proxy
2025-05-18 20:35:02 [ℹ]  successfully created addon: kube-proxy
2025-05-18 20:35:03 [ℹ]  creating addon: coredns
2025-05-18 20:35:03 [ℹ]  successfully created addon: coredns
2025-05-18 20:37:15 [ℹ]  addon "vpc-cni" active
2025-05-18 20:37:16 [ℹ]  deploying stack "eksctl-eks-demo-addon-vpc-cni"
2025-05-18 20:37:16 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-vpc-cni"
2025-05-18 20:37:46 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-addon-vpc-cni"
2025-05-18 20:37:46 [ℹ]  updating addon
2025-05-18 20:37:56 [ℹ]  addon "vpc-cni" active
2025-05-18 20:37:57 [ℹ]  building managed nodegroup stack "eksctl-eks-demo-nodegroup-node-group"
2025-05-18 20:37:57 [ℹ]  deploying stack "eksctl-eks-demo-nodegroup-node-group"
2025-05-18 20:37:57 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-node-group"
2025-05-18 20:38:27 [ℹ]  waiting for CloudFormation stack "eksctl-eks-demo-nodegroup-node-group"



eksctl delete cluster -f eks/eks-demo-cluster.yaml
```

## install ALB
```
./install-aws-lb.controller.sh
```

## kubectl 변경
```
aws eks update-kubeconfig --name eks-demo --region ap-northeast-2
```


### ubuntu 이미지 확인
```
 aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*" \
            "Name=virtualization-type,Values=hvm" \
  --query 'Images[*].[ImageId,CreationDate]' \
  --output text | sort -k2 -r | head -n1

ami-0da5bcddc13b7a13b   2025-05-08T11:45:11.000Z
```

