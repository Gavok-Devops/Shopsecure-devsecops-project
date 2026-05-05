# 🛡️ ShopSecure — Three-Tier DevSecOps Platform on AWS EKS

[![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)](https://argoproj.github.io/cd/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI-D24939?logo=jenkins)](https://www.jenkins.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana)](https://grafana.com/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws)](https://aws.amazon.com/eks/)

**ShopSecure** is a production-grade, cloud-native e-commerce platform demonstrating a full **DevSecOps lifecycle** on AWS EKS — from infrastructure provisioning with Terraform through automated CI/CD with Jenkins, GitOps delivery via ArgoCD, and real-time observability with Prometheus and Grafana.

---

## 📐 Architecture Overview

```
                    ┌──────────────────────────┐
                    │    CloudFront + WAFv2     │
                    │  (CDN, DDoS, Rate Limit)  │
                    └──────────┬───────────────┘
                               │ HTTPS (ACM TLS)
                    ┌──────────▼───────────────┐
                    │   Application Load Balancer│
                    └──────────┬───────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼──────┐    ┌──────────▼──────┐    ┌─────────▼──────┐
│   Frontend   │    │  Auth Service   │    │Product Service │
│ React + NGINX│    │   Node.js/JWT   │    │ Python FastAPI  │
└──────────────┘    └─────────────────┘    └────────────────┘
        │                      │                      │
┌───────▼──────┐    ┌──────────▼──────────────────────▼──────┐
│Order Service │    │              Data Tier                  │
│   Go / Gin   │    │  ┌──────────┐  ┌────────────────────┐  │
└───────┬──────┘    │  │RDS PG 16 │  │ ElastiCache Redis  │  │
        │           │  │(Multi-AZ)│  │  (Encrypted)       │  │
┌───────▼──────┐    │  └──────────┘  └────────────────────┘  │
│Payment Svc   │    │  ┌──────────┐  ┌────────────────────┐  │
│  Node.js     │    │  │    S3    │  │       SQS          │  │
└──────────────┘    │  └──────────┘  └────────────────────┘  │
                    └────────────────────────────────────────┘
```

### Three Tiers

| Tier | Components | Technology |
|------|-----------|-----------|
| **Tier 1 — Frontend** | React SPA, NGINX reverse proxy, CloudFront CDN | React 18, NGINX 1.27, AWS CloudFront |
| **Tier 2 — Backend API** | Auth, Products, Orders, Payments microservices | Node.js, Python FastAPI, Go, gRPC |
| **Tier 3 — Data** | Relational DB, cache, object store, message queue | RDS PostgreSQL 16, ElastiCache Redis, S3, SQS |

### DevSecOps Toolchain

| Tool | Role |
|------|------|
| **Terraform** | Provisions all AWS infrastructure as code |
| **Jenkins** | CI pipeline — build, SAST, container scan, ECR push |
| **ArgoCD** | GitOps CD — declarative Kubernetes deployments |
| **Prometheus** | Metrics collection from pods, nodes, and services |
| **Grafana** | Dashboards, alerting, SLO/SLA tracking |

---

## 📁 Repository Structure

```
shopsecure/
├── terraform/
│   ├── modules/
│   │   ├── vpc/          # VPC, subnets (3 AZs), NAT gateways, route tables
│   │   ├── eks/          # EKS cluster, node groups, OIDC, KMS encryption
│   │   ├── rds/          # PostgreSQL Multi-AZ, Secrets Manager integration
│   │   ├── elasticache/  # Redis replication group, encryption in-transit
│   │   ├── ecr/          # ECR repositories + lifecycle policies
│   │   ├── iam/          # IAM roles and policies for IRSA
│   │   └── security/     # WAFv2 managed rules, security groups
│   ├── environments/
│   │   ├── dev/          # Dev environment (smaller instances, 1 AZ)
│   │   ├── staging/      # Staging environment (medium, 2 AZs)
│   │   └── prod/         # Production (full HA, Multi-AZ, encryption)
│   └── global/           # Route53 hosted zone + ACM TLS certificate
├── kubernetes/
│   ├── base/             # Kustomize base manifests per service
│   ├── overlays/         # Per-environment patches (dev/staging/prod)
│   └── argocd/           # AppProject + Application CRDs (App-of-Apps)
├── services/
│   ├── frontend/         # React 18 + Vite + NGINX
│   ├── auth-service/     # Node.js + Express + JWT
│   ├── product-service/  # Python FastAPI + async DB
│   ├── order-service/    # Go + Gin (scratch container)
│   └── payment-service/  # Node.js + Stripe integration
├── jenkins/
│   ├── Jenkinsfile       # 8-stage DevSecOps pipeline
│   └── pipelines/        # Service pipelines + smoke tests
├── monitoring/
│   ├── alerts/           # PrometheusRule CRDs (7 alert rules)
│   ├── dashboards/       # Grafana dashboard JSON
│   └── servicemonitor.yaml
├── scripts/
│   ├── bootstrap-backend.sh  # One-time S3 + DynamoDB setup
│   └── install-tools.sh      # Install all CLI tools (macOS/Linux)
└── docs/
    ├── architecture.md   # Full architecture diagrams
    └── runbook.md        # Quick-start command reference
```

---

## 🚀 PART A — IMPLEMENTATION RUNBOOK

> **Estimated total time:** 2.5 – 3.5 hours
> Complete every phase in order. Each phase depends on the previous one.

---

### Phase 0 — Prerequisites & Local Setup
**Time: 30–60 minutes**

#### Step 0.1 — Install Required Tools

**macOS (Homebrew):**
```bash
# Automated installer
bash scripts/install-tools.sh

# Or install manually:
brew install awscli
brew install tfenv && tfenv install 1.7.5 && tfenv use 1.7.5
brew install kubectl helm argocd
brew install --cask docker
brew install jq yq trivy gitleaks
```

**Linux (Ubuntu/Debian):**
```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install

# Terraform
curl -sLO https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip && sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

#### Step 0.2 — Verify Tool Versions

```bash
aws       --version          # aws-cli/2.x.x
terraform --version          # Terraform v1.7.x
kubectl   version --client   # v1.31.x
helm      version --short    # v3.14.x
argocd    version --client   # argocd: v2.x.x
docker    --version          # Docker Engine x.x.x
trivy     --version          # Version: 0.x.x
```

#### Step 0.3 — Configure AWS CLI

```bash
aws configure
# AWS Access Key ID:     AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key: wJalrXUtn...
# Default region name:   us-east-1
# Default output format: json

# Verify identity
aws sts get-caller-identity

# Export for use throughout this runbook
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1
echo "Account: $AWS_ACCOUNT_ID  Region: $AWS_REGION"
```

> ⚠️ Your IAM user needs **Administrator or PowerUser** permissions. For production, create a dedicated `terraform-deploy` IAM role with least-privilege policies.

#### Step 0.4 — Clone the Repository

```bash
git clone https://github.com/YOUR_ORG/shopsecure.git
cd shopsecure
ls -la
# Expected: terraform/ kubernetes/ services/ jenkins/ monitoring/ scripts/ docs/
```

#### Step 0.5 — Verify AWS Service Quotas

```bash
# EKS cluster quota (need at least 2 available)
aws service-quotas get-service-quota --service-code eks --quota-code L-1194D53C

# EC2 vCPU quota for running instances (need at least 32)
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A

# Elastic IP quota (need at least 3 for NAT gateways)
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3
```

> ⚠️ If any quota is near the limit, request an increase before proceeding. Increases can take 24–48 hours.

---

### Phase 1 — Bootstrap Terraform Backend
**Time: 5 minutes** | Run ONCE per AWS account.

```bash
# Step 1: Run bootstrap script
bash scripts/bootstrap-backend.sh
# Output:
#   S3 Bucket:       shopsecure-terraform-state-123456789012
#   DynamoDB Table:  shopsecure-terraform-locks

# Step 2: Inject real account ID into Terraform backend configs
sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" terraform/environments/prod/main.tf
sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" terraform/environments/staging/main.tf
sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" terraform/environments/dev/main.tf
sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" terraform/global/main.tf

# Step 3: Update ECR references in Kubernetes manifests
find kubernetes/ -name "*.yaml" \
  -exec sed -i "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" {} \;
```

---

### Phase 2 — Provision Global Resources (Route53 + ACM)
**Time: 10 minutes + DNS propagation (up to 48 hours)**

```bash
# Step 1: Set your domain in terraform/global/main.tf
# Change: variable "domain_name" { default = "shopsecure.io" }
# To your real domain

# Step 2: Apply
cd terraform/global
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Step 3: Copy nameservers to your domain registrar
terraform output name_servers

# Step 4: Monitor certificate validation (must show ISSUED before ALB setup)
aws acm list-certificates --region us-east-1 \
  --query 'CertificateSummaryList[*].{Domain:DomainName,Status:Status}'
cd ..
```

---

### Phase 3 — Provision AWS Infrastructure (Terraform)
**Time: 25–35 minutes**

Creates: VPC (3 AZs) · EKS 1.31 · RDS PostgreSQL 16 (Multi-AZ) · ElastiCache Redis · ECR (×5 repos) · WAFv2 · IAM roles

```bash
# ── Production ───────────────────────────────────────────────────────────────
cd terraform/environments/prod

# Initialize (downloads providers, configures S3 backend)
terraform init
# Expected: Terraform has been successfully initialized!

# Validate and format
terraform validate && terraform fmt -recursive .

# Plan — review EVERY resource, especially look for unexpected deletions
terraform plan -out=tfplan 2>&1 | tee plan.log
# Expected: Plan: ~60 to add, 0 to change, 0 to destroy

# Apply — do NOT interrupt, takes 20–30 minutes
terraform apply tfplan
# Expected: Apply complete! Resources: ~60 added.

# Save outputs for later phases
terraform output -json > /tmp/tf-outputs.json
cd ../../..
```

> 💡 If `terraform apply` fails mid-way, run it again — Terraform is idempotent and resumes. Do **NOT** run `terraform destroy` between retries.

#### Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name shopsecure-prod --region us-east-1

# Verify all nodes are Ready
kubectl get nodes -o wide
# Expected: 5 nodes, STATUS=Ready

# Verify system pods
kubectl get pods -n kube-system
# Expected: All Running or Completed
```

#### Install AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts && helm repo update

eksctl create iamserviceaccount \
  --cluster=shopsecure-prod --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess \
  --override-existing-serviceaccounts --approve

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=shopsecure-prod \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --wait

# Create application namespaces
kubectl apply -f kubernetes/base/namespaces.yaml
```

---

### Phase 4 — Install Jenkins (CI)
**Time: 15 minutes**

```bash
helm repo add jenkins https://charts.jenkins.io && helm repo update
kubectl create namespace jenkins

# Create admin password secret
JENKINS_PASS=$(openssl rand -base64 24)
kubectl create secret generic jenkins-admin-secret \
  --from-literal=jenkins-admin-user=admin \
  --from-literal=jenkins-admin-password="$JENKINS_PASS" \
  -n jenkins
echo "Jenkins password: $JENKINS_PASS"  # ← SAVE THIS

# Install Jenkins with DevSecOps plugins
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --set controller.serviceType=LoadBalancer \
  --set controller.resources.limits.memory=2Gi \
  --set controller.resources.requests.cpu=500m \
  --set persistence.enabled=true --set persistence.size=20Gi \
  --set controller.installPlugins[0]=kubernetes \
  --set controller.installPlugins[1]=git \
  --set controller.installPlugins[2]=pipeline-aws \
  --set controller.installPlugins[3]=docker-workflow \
  --set controller.installPlugins[4]=sonarqube-scanner \
  --set controller.installPlugins[5]=owasp-dependency-check \
  --set controller.installPlugins[6]=slack \
  --set controller.installPlugins[7]=blueocean \
  --wait --timeout 10m

# Get Jenkins URL
kubectl get svc jenkins -n jenkins \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Attach ECR permissions to Jenkins worker nodes
NODE_ROLE=$(aws eks describe-nodegroup \
  --cluster-name shopsecure-prod --nodegroup-name application \
  --query 'nodegroup.nodeRole' --output text | awk -F/ '{print $NF}')
aws iam attach-role-policy --role-name $NODE_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
```

**Manual steps in Jenkins UI:**
1. **Manage Jenkins → Credentials → Global → Add Credentials**
2. Add `github-token` (Secret text — GitHub personal access token)
3. Add `AWS_ACCOUNT_ID` (Secret text — your AWS account ID)
4. Create a Pipeline job → Script from SCM → `jenkins/Jenkinsfile`

---

### Phase 5 — Install ArgoCD (GitOps CD)
**Time: 20 minutes**

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for all pods
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s

# Expose as LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"LoadBalancer"}}'

# Get URL and initial password
export ARGOCD_URL=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "URL: $ARGOCD_URL  |  Password: $ARGOCD_PASS"

# Login and change password immediately
argocd login $ARGOCD_URL --username admin --password $ARGOCD_PASS --grpc-web
argocd account update-password \
  --current-password $ARGOCD_PASS \
  --new-password 'YourStrongPassword123!'

# Connect GitHub repo
argocd repo add https://github.com/YOUR_ORG/shopsecure.git \
  --username git --password YOUR_GITHUB_TOKEN

# Deploy App-of-Apps
find kubernetes/argocd -name '*.yaml' \
  -exec sed -i 's/YOUR_ORG/your-github-org/g' {} \;
kubectl apply -f kubernetes/argocd/project.yaml
kubectl apply -f kubernetes/argocd/apps/root.yaml

# Verify
argocd app list
# Expected: All apps show Synced + Healthy
```

---

### Phase 6 — Install Prometheus & Grafana (Observability)
**Time: 20 minutes**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring

GRAFANA_PASS=$(openssl rand -base64 20)
echo "Grafana password: $GRAFANA_PASS"  # ← SAVE THIS

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.retentionSize=50GB \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword="$GRAFANA_PASS" \
  --set grafana.service.type=LoadBalancer \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.size=10Gi \
  --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --wait --timeout 15m

# Apply ShopSecure alert rules and service monitors
kubectl apply -f monitoring/alerts/shopsecure-alerts.yaml
kubectl apply -f monitoring/servicemonitor.yaml

# Get Grafana URL
kubectl get svc kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Import these Grafana dashboards** (Dashboards → Import by ID):

| ID | Dashboard Name |
|----|---------------|
| `6417` | Kubernetes Cluster Overview |
| `14205` | Kubernetes Namespaces |
| `9614` | NGINX Ingress Controller |
| `14584` | ArgoCD |
| `1860` | Node Exporter Full |

---

### Phase 7 — Build & Push Service Images
**Time: 15–30 minutes**

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push all services
for svc in frontend auth-service product-service order-service payment-service; do
  echo "Building $svc..."
  docker build --no-cache \
    -t $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/shopsecure/$svc:latest \
    services/$svc/
  docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/shopsecure/$svc:latest
done

# Update kustomization files with real ECR URI
find kubernetes/overlays -name "kustomization.yaml" \
  -exec sed -i \
  "s|REGISTRY|$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com|g" {} \;

# Commit — ArgoCD auto-deploys on git push
git add kubernetes/
git commit -m 'feat: set real ECR image URIs for prod'
git push origin main
```

---

### Phase 8 — Verify Full Stack
**Time: 20 minutes**

```bash
# Infrastructure checks
aws eks describe-cluster --name shopsecure-prod --query 'cluster.status'
# Expected: "ACTIVE"

kubectl get nodes            # All STATUS=Ready
kubectl get pods -A | grep -v Running | grep -v Completed  # Should be empty
argocd app list              # All Synced + Healthy

# Run smoke tests
export BASE_URL=https://api.shopsecure.io
bash jenkins/pipelines/smoke-test.sh
# Expected: 5 passed, 0 failed — ALL SMOKE TESTS PASSED

# Verify observability
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090 &
open http://localhost:9090/targets  # All targets should be UP
```

---

### Phase 9 — Wire CI/CD End-to-End
**Time: 15 minutes**

```bash
# 1. Create GitHub webhook
# GitHub → Repo → Settings → Webhooks → Add webhook
# Payload URL: http://JENKINS_URL/github-webhook/
# Content type: application/json  |  Events: Push

# 2. Test the full pipeline
echo '// ci test' >> services/auth-service/src/index.js
git add -A && git commit -m 'test: trigger CI pipeline'
git push origin main

# 3. Watch ArgoCD auto-sync after Jenkins completes
argocd app get auth-service --watch

# 4. Verify rolling deployment completes
kubectl rollout status deployment/auth-service -n shopsecure-prod
```

---

### Implementation Phase Summary

| Phase | Description | Time |
|-------|------------|------|
| Phase 0 | Prerequisites & tool installation | 30–60 min |
| Phase 1 | Bootstrap Terraform backend | 5 min |
| Phase 2 | Route53 + ACM certificate | 10 min + DNS |
| Phase 3 | VPC, EKS, RDS, ElastiCache, ECR via Terraform | 25–35 min |
| Phase 4 | Jenkins CI on EKS | 15 min |
| Phase 5 | ArgoCD GitOps CD | 20 min |
| Phase 6 | Prometheus + Grafana observability | 20 min |
| Phase 7 | Build & push 5 service images | 15–30 min |
| Phase 8 | Verify + smoke tests | 20 min |
| Phase 9 | CI/CD wiring + end-to-end test | 15 min |
| **Total** | | **~2.5 – 3.5 hours** |

---

## 💥 PART B — TEARDOWN RUNBOOK

> ⛔ **WARNING: Teardown is IRREVERSIBLE.** All RDS data, ElastiCache data, and application state will be permanently deleted. Take a final backup and notify stakeholders before proceeding.

**Destroy in this exact order:** Applications → Helm releases → Kubernetes resources → AWS infrastructure → Backend state

---

### Phase T0 — Pre-Teardown Checklist
**Time: 15–30 minutes**

```bash
# Take final RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier shopsecure-postgres-prod \
  --db-snapshot-identifier shopsecure-final-backup-$(date +%Y%m%d)

aws rds wait db-snapshot-completed \
  --db-snapshot-identifier shopsecure-final-backup-$(date +%Y%m%d)
echo "Snapshot complete"

# Back up Jenkins job configs
kubectl cp \
  jenkins/$(kubectl get pod -n jenkins \
    -l app.kubernetes.io/component=jenkins-controller \
    -o jsonpath='{.items[0].metadata.name}'):/var/jenkins_home/jobs/ \
  ./jenkins-backup/

# Record all external URLs before they disappear
kubectl get svc -A | grep LoadBalancer
argocd app list
```

---

### Phase T1 — Stop All CI/CD Activity
**Time: 5 minutes**

```bash
# Disable ArgoCD auto-sync for all applications
argocd app list -o name | \
  xargs -I{} argocd app set {} --sync-policy none
echo "ArgoCD auto-sync disabled for all apps"

# Suspend HPAs to prevent scale-up during teardown
kubectl get hpa -n shopsecure-prod -o name | \
  xargs -I{} kubectl patch {} -n shopsecure-prod \
  -p '{"spec":{"maxReplicas":0}}'
```

---

### Phase T2 — Delete ArgoCD Applications
**Time: 5–10 minutes**

```bash
# Cascade-delete all managed applications (also removes K8s resources)
argocd app list -o name | \
  xargs -I{} argocd app delete {} --cascade --yes
echo "Waiting for pods to terminate..."
sleep 45

# Clean up remaining ArgoCD resources
kubectl delete application shopsecure-root -n argocd --ignore-not-found
kubectl delete -f kubernetes/argocd/project.yaml --ignore-not-found

# Confirm all app pods are gone
kubectl get pods -n shopsecure-prod
# Expected: No resources found in shopsecure-prod namespace.
```

---

### Phase T3 — Uninstall Helm Releases
**Time: 10 minutes**

```bash
# 1. Monitoring stack
helm uninstall kube-prometheus-stack -n monitoring
kubectl delete pvc --all -n monitoring
kubectl delete namespace monitoring --ignore-not-found

# 2. Jenkins
helm uninstall jenkins -n jenkins
kubectl delete pvc --all -n jenkins
kubectl delete namespace jenkins --ignore-not-found

# 3. ArgoCD
kubectl delete -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd --ignore-not-found

# 4. AWS Load Balancer Controller (MUST be removed before EKS destroy)
helm uninstall aws-load-balancer-controller -n kube-system

# 5. Delete application namespaces (takes 2–5 min)
kubectl delete namespace \
  shopsecure-prod shopsecure-staging shopsecure-dev \
  --ignore-not-found
kubectl get namespaces | grep shopsecure  # Should be empty

# 6. Verify no orphaned ALBs remain — delete manually if found!
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}'
```

---

### Phase T4 — Destroy AWS Infrastructure (Terraform)
**Time: 30–50 minutes**

> ⛔ Destroy order is **critical**: `prod → staging → dev → global`. Type `yes` when prompted.

```bash
# ── Production ───────────────────────────────────────────────────────────────
cd terraform/environments/prod
terraform destroy
# Type: yes
# Expected: Destroy complete! Resources: ~60 destroyed.
cd ../../..

# Verify RDS and ElastiCache are gone
aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}'
aws elasticache describe-replication-groups \
  --query 'ReplicationGroups[*].{ID:ReplicationGroupId,Status:Status}'

# ── Staging ───────────────────────────────────────────────────────────────────
cd terraform/environments/staging
terraform destroy   # Type: yes
cd ../../..

# ── Dev ───────────────────────────────────────────────────────────────────────
cd terraform/environments/dev
terraform destroy   # Type: yes
cd ../../..

# ── Global (Route53 + ACM) ────────────────────────────────────────────────────
cd terraform/global
terraform destroy   # Type: yes
cd ..

# Check no EC2 instances remain
aws ec2 describe-instances \
  --filters 'Name=instance-state-name,Values=running' \
  --query 'Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key==`Name`]|[0].Value}' \
  --output table

# Release any unattached Elastic IPs (~$3.65/month each if left running)
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].AllocationId' \
  --output text | \
  xargs -I{} aws ec2 release-address --allocation-id {}
```

---

### Phase T5 — Delete ECR Images & Repositories
**Time: 5 minutes**

```bash
for repo in frontend auth-service product-service order-service payment-service; do
  echo "Cleaning shopsecure/$repo..."
  IMAGES=$(aws ecr list-images \
    --repository-name shopsecure/$repo \
    --query 'imageIds[*]' --output json)
  if [ "$IMAGES" != "[]" ]; then
    aws ecr batch-delete-image \
      --repository-name shopsecure/$repo \
      --image-ids "$IMAGES"
  fi
  aws ecr delete-repository \
    --repository-name shopsecure/$repo --force
  echo "Deleted shopsecure/$repo"
done
```

---

### Phase T6 — Delete Terraform Backend *(Optional — permanent)*
**Time: 5 minutes**

> ⚠️ Only do this if permanently decommissioning. This deletes ALL Terraform state history.

```bash
BUCKET=shopsecure-terraform-state-$AWS_ACCOUNT_ID

# Delete all object versions (required for versioned buckets)
aws s3api list-object-versions --bucket $BUCKET --output json | \
  jq -r '.Versions[],.DeleteMarkers[] | "\(.Key) \(.VersionId)"' 2>/dev/null | \
  while read key vid; do
    aws s3api delete-object --bucket $BUCKET --key "$key" --version-id "$vid"
  done

aws s3 rb s3://$BUCKET
echo "State bucket deleted"

aws dynamodb delete-table \
  --table-name shopsecure-terraform-locks \
  --region us-east-1
echo "Lock table deleted"
```

---

### Phase T7 — Final Verification Checklist
**Time: 15 minutes**

| Resource | Where to Check | Expected State |
|----------|---------------|----------------|
| EKS Cluster | EKS Console → Clusters | No `shopsecure-*` clusters |
| EC2 Instances | EC2 → Running Instances | 0 instances |
| RDS Instances | RDS → Databases | 0 instances |
| ElastiCache | ElastiCache → Replication Groups | 0 groups |
| Load Balancers | EC2 → Load Balancers | 0 ALBs/NLBs |
| NAT Gateways | VPC → NAT Gateways | 0 in Available state |
| Elastic IPs | EC2 → Elastic IPs | 0 unassociated |
| ECR Repos | ECR → Repositories | 0 repos |
| S3 Buckets | S3 Console | State bucket deleted |
| IAM Roles | IAM → Roles | No `shopsecure-*` roles |
| Route53 | Route53 → Hosted Zones | Zone deleted |
| ACM Certs | ACM Console | Certificate deleted |

```bash
# Final cost check — should show $0.00
aws ce get-cost-and-usage \
  --time-period Start=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d '-1 day' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost'
```

> 💡 **CloudWatch Log Groups** (`/aws/eks/*`) and **RDS snapshots** are NOT deleted by `terraform destroy`. Delete manually for full $0 spend.

---

### Teardown Phase Summary

| Phase | Description | Time |
|-------|------------|------|
| T0 | Pre-teardown backups + notifications | 15–30 min |
| T1 | Stop Jenkins + disable ArgoCD auto-sync | 5 min |
| T2 | Delete ArgoCD applications (cascade) | 5–10 min |
| T3 | Helm uninstall: monitoring, Jenkins, ArgoCD, LBC | 10 min |
| T4 | Terraform destroy: prod → staging → dev → global | 30–50 min |
| T5 | Delete ECR images and repositories | 5 min |
| T6 | Delete S3 state + DynamoDB (optional) | 5 min |
| T7 | Verify $0 spend across all services | 15 min |
| **Total** | | **~1.5 – 2 hours** |

---

## 🔑 Quick Reference

### Retrieve Credentials & URLs

```bash
# EKS kubeconfig
aws eks update-kubeconfig --name shopsecure-prod --region us-east-1

# ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Grafana admin password
kubectl get secret kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo

# Jenkins admin password
kubectl exec -n jenkins svc/jenkins -c jenkins -- \
  cat /run/secrets/additional/chart-admin-password && echo

# Database connection string
aws secretsmanager get-secret-value \
  --secret-id shopsecure/prod/database | jq -r .SecretString

# All LoadBalancer external URLs
kubectl get svc -A | grep LoadBalancer
```

### Common Day-2 Operations

```bash
# Scale a service
kubectl scale deployment product-service --replicas=5 -n shopsecure-prod

# Roll back (GitOps — preferred)
argocd app rollback product-service

# Roll back via kubectl
kubectl rollout undo deployment/product-service -n shopsecure-prod

# Stream pod logs
kubectl logs -f deployment/product-service -n shopsecure-prod --tail=100

# Exec into running pod
kubectl exec -it deploy/product-service -n shopsecure-prod -- /bin/sh

# Get recent cluster events
kubectl get events -n shopsecure-prod --sort-by='.lastTimestamp' | tail -20

# Port-forward Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090

# Terraform state operations
cd terraform/environments/prod
terraform state list
terraform state show module.eks.aws_eks_cluster.main
```

### Alert Rules Reference

| Alert | Condition | Severity |
|-------|-----------|----------|
| `ServiceDown` | Pod unreachable for >2 min | Critical |
| `HighErrorRate` | HTTP 5xx rate >5% for 5 min | Critical |
| `HighP99Latency` | P99 latency >2s for 5 min | Warning |
| `PodCrashLooping` | Restart rate >0 for 5 min | Warning |
| `PodOOMKilled` | Container OOM killed | Warning |
| `NodeHighCPU` | CPU >85% for 10 min | Warning |
| `NodeDiskPressure` | Disk <15% free | Critical |

---

## 💰 Estimated Monthly Cost (Production)

| Resource | Configuration | Est. Cost |
|----------|--------------|-----------|
| EKS Control Plane | 1 cluster | ~$72 |
| EC2 m5.large — System nodes | 2× On-Demand | ~$139 |
| EC2 m5.xlarge — App nodes (Spot) | 3× Spot | ~$130 |
| RDS PostgreSQL db.m5.large | Multi-AZ | ~$151 |
| ElastiCache cache.m5.large | 1 node | ~$91 |
| Application Load Balancers | 2× ALB | ~$45 |
| CloudFront CDN | ~1 TB transfer | ~$85 |
| ECR + S3 + CloudWatch | ~550 GB | ~$42 |
| Data Transfer | ~500 GB outbound | ~$45 |
| **Total** | | **~$800–$1,000/month** |

> 💡 Save 30–50% with Reserved Instances or Compute Savings Plans.

---

## 🔒 Security Controls

| Layer | Control |
|-------|---------|
| Network perimeter | VPC private subnets, NACLs, WAFv2 managed rules + rate limiting |
| EKS API | Private endpoint, RBAC, OIDC/IRSA for least-privilege pod roles |
| Workload | Pod Security Standards (restricted), NetworkPolicy (zero-trust), non-root |
| Secrets | AWS Secrets Manager + External Secrets Operator |
| Images | ECR scan-on-push, Trivy in CI (blocks HIGH/CRITICAL CVEs) |
| Code | SonarQube Quality Gate, OWASP Dependency Check, gitleaks |
| Audit | CloudTrail, EKS audit logs → CloudWatch (30-day retention) |
| TLS | ACM wildcard cert, HTTPS enforced, Redis encryption in-transit |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push and open a Pull Request
5. All PRs auto-trigger the Jenkins CI pipeline — security scans must pass

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

---

*ShopSecure DevSecOps Platform — Built for the cloud-native community*
