.PHONY: tf-init tf-plan tf-apply k8s-verify argocd-sync smoke-test

ENV ?= prod
REGION ?= us-east-1
CLUSTER ?= shopsecure-$(ENV)

tf-init:
	cd terraform/environments/$(ENV) && terraform init

tf-plan:
	cd terraform/environments/$(ENV) && terraform plan -out=tfplan

tf-apply:
	cd terraform/environments/$(ENV) && terraform apply tfplan

kubeconfig:
	aws eks update-kubeconfig --name $(CLUSTER) --region $(REGION)

k8s-verify:
	kubectl get nodes
	kubectl get pods -A

argocd-sync:
	argocd app sync --all --prune

smoke-test:
	bash jenkins/pipelines/smoke-test.sh
