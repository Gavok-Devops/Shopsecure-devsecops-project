#!/usr/bin/env bash
# scripts/install-tools.sh
# Install all required CLI tools on macOS (Homebrew) or Linux (apt/curl)
set -euo pipefail

OS="$(uname -s)"

install_brew() { brew install "$@"; }

install_linux() {
  local tool=$1
  echo "Manual install required for $tool on Linux. See runbook docs/."
}

echo "=== Installing ShopSecure DevSecOps Toolchain ==="

if [[ "$OS" == "Darwin" ]]; then
  # AWS CLI
  brew install awscli
  # Terraform via tfenv
  brew install tfenv && tfenv install 1.7.5 && tfenv use 1.7.5
  # kubectl
  brew install kubectl
  # Helm
  brew install helm
  # ArgoCD CLI
  brew install argocd
  # Docker (Desktop)
  brew install --cask docker
  # jq / yq
  brew install jq yq
  # Trivy (container scanner)
  brew install trivy
  # Gitleaks (secret scanner)
  brew install gitleaks
  # k9s (K8s TUI)
  brew install k9s
else
  # AWS CLI
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install

  # kubectl
  KUBECTL_VER=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -sLO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/

  # Helm
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  # Terraform
  TERRAFORM_VER="1.7.5"
  curl -sLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
  unzip "terraform_${TERRAFORM_VER}_linux_amd64.zip" && sudo mv terraform /usr/local/bin/

  # ArgoCD CLI
  ARGOCD_VER=$(curl -sL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
  curl -sLO "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VER}/argocd-linux-amd64"
  chmod +x argocd-linux-amd64 && sudo mv argocd-linux-amd64 /usr/local/bin/argocd
fi

echo ""
echo "=== Verifying installations ==="
aws      --version
terraform --version
kubectl  version --client --short 2>/dev/null || kubectl version --client
helm     version --short
argocd   version --client
echo "All tools installed successfully!"
