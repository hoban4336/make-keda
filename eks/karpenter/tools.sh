#!/bin/bash

# ----- AWS CLI v2 설치 (없을 경우) -----
if ! command -v aws &> /dev/null; then
  echo "Installing AWS CLI v2..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  echo 'export AWS_PAGER=""' >> ~/.bashrc
else
  echo "AWS CLI already installed."
fi

# ----- kubectl 설치 (없을 경우) -----
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
else
  echo "kubectl already installed."
fi

# ----- eksctl 설치 (없을 경우) -----
if ! command -v eksctl &> /dev/null; then
  echo "Installing eksctl..."
  curl -sL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz
  sudo mv eksctl /usr/local/bin/
else
  echo "eksctl already installed."
fi

# ----- helm 설치 (없을 경우) -----
if ! command -v helm &> /dev/null; then
  echo "Installing helm..."
  curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
else
  echo "helm already installed."
fi

# ----- krew 설치 (없을 경우) -----
if ! command -v kubectl-krew &> /dev/null; then
  echo "Installing krew..."
  (
    set -x
    cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/arm.*$/arm/')" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-${OS}_${ARCH}.tar.gz" &&
    tar zxvf krew-${OS}_${ARCH}.tar.gz &&
    ./krew-${OS}_${ARCH} install krew
  )
  echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
else
  echo "krew already installed."
fi

# ----- krew 플러그인 설치 -----
for plugin in ctx ns neat get-all df-pv stern view-secret; do
  if ! kubectl krew list | grep -q "$plugin"; then
    echo "Installing krew plugin: $plugin"
    kubectl krew install "$plugin"
  else
    echo "krew plugin '$plugin' already installed."
  fi
done

# ----- kubecolor 설치 (없을 경우) -----
if ! command -v kubecolor &> /dev/null; then
  echo "Installing kubecolor..."
  curl -LO https://github.com/kubecolor/kubecolor/releases/download/v0.5.0/kubecolor_0.5.0_linux_amd64.tar.gz
  tar -zxvf kubecolor_0.5.0_linux_amd64.tar.gz
  sudo mv kubecolor /usr/local/bin/
else
  echo "kubecolor already installed."
fi

echo "✅ 모든 설치가 완료되었습니다."
