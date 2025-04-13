kubectl create secret generic authentik-secret-key \
  --from-literal=AUTHENTIK_SECRET_KEY="$(openssl rand -hex 32)" \
  -n auth-proxy

