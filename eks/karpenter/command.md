

✅ cloudformation.yaml의 실제 목적
AWS 공식 Karpenter 설치 가이드에서 제공하는 이 CloudFormation 템플릿은 다음 리소스를 생성합니다:

| 리소스 이름                              | 설명                                                                              |
| ----------------------------------- | ------------------------------------------------------------------------------- |
| **KarpenterNodeRole-\***            | EC2 인스턴스에 부여될 IAM Role                                                          |
| **KarpenterNodeInstanceProfile-\*** | EC2 시작 시 사용하는 Instance Profile                                                  |
| **KarpenterControllerPolicy-\***    | Karpenter Controller가 EC2, Auto Scaling, Pricing API를 호출할 수 있도록 허용하는 IAM Policy |
| **Service-linked roles (자동 생성)**    | Spot Fleet 등을 위한 AWS 내부 역할                                                      |
