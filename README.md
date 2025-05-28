
## Command
```
make build_microk8s
make deploy
```


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

### REF 
- https://guide-fin.ncloud-docs.com/docs/k8s-k8sexamples-albingress


ncloud@10.105.90.36

클라이언트 브라우저
   ↓ Host: y-nginx.hav-ing.store
ALB (Ingress)
   ↓
NGINX
   → auth_request: /outpost.goauthentik.io/auth/nginx
     → proxy_pass: http://authentik-server.auth-proxy.svc.cluster.local/auth/nginx
     → Host header: y-nginx.hav-ing.store
     ✅ Authentik는 Provider 찾음

→ 401 → /start redirect → 로그인
→ 로그인 완료 후 rd=... 으로 redirect