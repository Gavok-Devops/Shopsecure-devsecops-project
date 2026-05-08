#!/usr/bin/env bash
# scripts/wire-dns.sh
# Run AFTER all services are deployed to create Route53 DNS records
# pointing teamcsolutions.com subdomains to your LoadBalancers
set -euo pipefail

REGION="us-east-1"
DOMAIN="teamcsolutions.com"
ZONE_ID="Z05185392LBZP0EFHCEN7"

echo "================================================"
echo " ShopSecure — Wire DNS Records"
echo " Domain:  $DOMAIN"
echo " Zone ID: $ZONE_ID"
echo "================================================"

# Get LoadBalancer hostnames
echo "Fetching LoadBalancer hostnames..."

JENKINS_LB=$(kubectl get svc jenkins -n jenkins \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
ARGOCD_LB=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
GRAFANA_LB=$(kubectl get svc kube-prometheus-stack-grafana -n monitoring \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
APP_LB=$(kubectl get ingress shopsecure-ingress -n shopsecure-prod \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

echo ""
echo "LoadBalancer hostnames:"
echo "  Jenkins:  ${JENKINS_LB:-NOT FOUND}"
echo "  ArgoCD:   ${ARGOCD_LB:-NOT FOUND}"
echo "  Grafana:  ${GRAFANA_LB:-NOT FOUND}"
echo "  App:      ${APP_LB:-NOT FOUND}"
echo ""

create_cname() {
  local subdomain="$1"
  local target="$2"
  if [ -z "$target" ]; then
    echo "⚠  Skipping $subdomain.$DOMAIN — LoadBalancer not ready"
    return
  fi
  echo "Creating CNAME: $subdomain.$DOMAIN → $target"
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$subdomain.$DOMAIN\",
          \"Type\": \"CNAME\",
          \"TTL\": 300,
          \"ResourceRecords\": [{\"Value\": \"$target\"}]
        }
      }]
    }" > /dev/null
  echo "✓ $subdomain.$DOMAIN → $target"
}

create_cname "jenkins"  "$JENKINS_LB"
create_cname "argocd"   "$ARGOCD_LB"
create_cname "grafana"  "$GRAFANA_LB"
create_cname "app"      "$APP_LB"
create_cname "api"      "$APP_LB"

echo ""
echo "================================================"
echo " DNS records created! URLs:"
echo ""
[ -n "$JENKINS_LB" ] && echo "  Jenkins:  https://jenkins.$DOMAIN"
[ -n "$ARGOCD_LB"  ] && echo "  ArgoCD:   https://argocd.$DOMAIN"
[ -n "$GRAFANA_LB" ] && echo "  Grafana:  https://grafana.$DOMAIN"
[ -n "$APP_LB"     ] && echo "  App:      https://app.$DOMAIN"
[ -n "$APP_LB"     ] && echo "  API:      https://api.$DOMAIN"
echo ""
echo " Note: DNS propagation takes 1-5 minutes"
echo "================================================"
