

## 📁 디렉토리 구조 예시 (서비스 디렉토리별)
```
{Project}/
  ├── Dockerfile
  ├── deployment.yaml       # 일반 K8s Deployment
  ├── scaledobject.yaml     # KEDA의 ScaledObject
```



### Trouble Shooting 

#### Docker 권한 없는 경우
```bash
# 권한 추가
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

```bash
# docker 재시작
sudo systemctl status docker
```
