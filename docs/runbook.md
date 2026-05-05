# ShopSecure — Quick Start Runbook

> Full runbook: see the `devsecops-eks-runbook.docx` in this repo's root.

## 1. Bootstrap (one-time)
```bash
bash scripts/bootstrap-backend.sh
# Then update ACCOUNT_ID in all terraform/environments/*/main.tf
```

## 2. Provision Infrastructure
```bash
cd terraform/environments/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
aws eks update-kubeconfig --name shopsecure-prod --region us-east-1
kubectl get nodes
```

## 3. Install Platform Components
```bash
# AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts && helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system --set clusterName=shopsecure-prod

# ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Jenkins
helm repo add jenkins https://charts.jenkins.io && helm repo update
helm upgrade --install jenkins jenkins/jenkins -n jenkins --create-namespace \
  --set controller.serviceType=LoadBalancer --set persistence.enabled=true

# Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace --set grafana.service.type=LoadBalancer
```

## 4. Deploy Applications
```bash
kubectl apply -f kubernetes/argocd/project.yaml
kubectl apply -f kubernetes/argocd/apps/root.yaml
argocd app list
```

## 5. Verify
```bash
kubectl get nodes
kubectl get pods -A
argocd app list
bash jenkins/pipelines/smoke-test.sh
```

## Common Commands

```bash
# Scale a service
kubectl scale deployment product-service --replicas=5 -n shopsecure-prod

# Roll back (GitOps)
argocd app rollback product-service

# Stream logs
kubectl logs -f deployment/product-service -n shopsecure-prod

# Get Grafana password
kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Terraform state operations
cd terraform/environments/prod
terraform state list
terraform state show module.eks.aws_eks_cluster.main
```
