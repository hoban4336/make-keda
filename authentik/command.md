kubectl create secret generic authentik-secret-key \
  --from-literal=AUTHENTIK_SECRET_KEY="$(openssl rand -hex 32)" \
  -n auth-proxy

# 설계안

1. ALB Ingress + Authentik
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: spring-authentik-ingress
  namespace: spring-io
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: spring-alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/auth-type: authenticate
    alb.ingress.kubernetes.io/auth-idp-type: oidc
    alb.ingress.kubernetes.io/auth-idp-oidc-issuer: https://auth.hav-ing.store/application/o/spring/
    alb.ingress.kubernetes.io/auth-on-unauthenticated-request: authenticate
    alb.ingress.kubernetes.io/auth-session-timeout: "3600"
    alb.ingress.kubernetes.io/auth-session-cookie: authentik-session
    alb.ingress.kubernetes.io/auth-scope: "openid email profile"
    alb.ingress.kubernetes.io/auth-user-pool-arn: "arn:aws:cognito:region:account:userpool/example"  # optional for AWS compatibility
spec:
  ingressClassName: alb
  rules:
    - host: y-spring-io.hav-ing.store
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: spring-io-service
                port:
                  number: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: spring-io-service
  namespace: spring-io
spec:
  selector:
    app: spring-io
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

2. NLB + NGINX 단독 Proxy + Authentik
```
helm:
  releaseName: spring-auth-protected
  namespace: spring-io
  chart: ingress-nginx
  repository: https://kubernetes.github.io/ingress-nginx
  version: 4.10.0
  values:
    controller:
      ingressClassResource:
        name: nginx
      config:
        enable-real-ip: "true"
      service:
        type: NodePort
        nodePorts:
          http: 30080
          https: 30443
        externalTrafficPolicy: Local
    ingress:
      enabled: true
      ingressClassName: nginx
      annotations:
        nginx.ingress.kubernetes.io/auth-url: "http://authentik-server.auth-proxy.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx"
        nginx.ingress.kubernetes.io/auth-signin: "https://auth.hav-ing.store/outpost.goauthentik.io/start?rd=$scheme://$host$request_uri"
        nginx.ingress.kubernetes.io/configuration-snippet: |
          proxy_set_header X-Original-URI $request_uri;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
      hosts:
        - host: y-spring-io.hav-ing.store
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: spring-io-service
                  port:
                    number: 80

---
apiVersion: v1
kind: Service
metadata:
  name: spring-io-service
  namespace: spring-io
spec:
  selector:
    app: spring-io
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

3. NGINX standalone + Authentik
```
helm:
  releaseName: spring-nginx-proxy
  namespace: spring-io
  chart: oci://ghcr.io/nginxinc/charts/nginx-ingress
  version: 1.1.3
  values:
    controller:
      replicaCount: 1
      service:
        type: NodePort
        nodePorts:
          http: 30080
        externalTrafficPolicy: Local
      config:
        entries:
          - key: server-snippet
            value: |
              location / {
                auth_request /auth;
                proxy_pass http://spring-io-service.spring-io.svc.cluster.local:8080;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Original-URI $request_uri;
              }
              location = /auth {
                internal;
                proxy_pass http://authentik-server.auth-proxy.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx;
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Host $host;
                proxy_set_header X-Original-URI $request_uri;
              }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-nginx-proxy
  namespace: spring-io
spec:
  replicas: 1
  selector:
    matchLabels:
      app: spring-nginx-proxy
  template:
    metadata:
      labels:
        app: spring-nginx-proxy
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx/conf.d/default.conf
              subPath: default.conf
      volumes:
        - name: nginx-config
          configMap:
            name: spring-nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: spring-nginx-config
  namespace: spring-io
  labels:
    app: spring-nginx-proxy
  annotations:
    managed-by: helm

data:
  default.conf: |
    server {
      listen 80;
      server_name y-spring-io.hav-ing.store;

      location / {
        auth_request /auth;
        proxy_pass http://spring-io-service.spring-io.svc.cluster.local:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Original-URI $request_uri;
      }

      location = /auth {
        internal;
        proxy_pass http://authentik-server.auth-proxy.svc.cluster.local:9000/outpost.goauthentik.io/auth/nginx;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header X-Original-URI $request_uri;
      }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: spring-nginx-proxy
  namespace: spring-io
spec:
  selector:
    app: spring-nginx-proxy
  type: NodePort
  ports:
    - name: http
      port: 80
      targetPort: 80
      nodePort: 30080
---
apiVersion: v1
kind: Service
metadata:
  name: spring-io-service
  namespace: spring-io
spec:
  selector:
    app: spring-io
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```