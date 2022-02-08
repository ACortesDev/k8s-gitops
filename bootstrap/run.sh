#!/bin/bash

export REPO_URL=https://github.com/ACortesDev/TrueDevOps
export AWS_ACCESS_KEY_ID=[...]
export AWS_SECRET_ACCESS_KEY=[...]

# Init
###################################################
# 1. Get a local cluster to use as a control plane
###################################################
k3d cluster create mycluster

################################################
# 2. Get the external IP of the Ingress service
################################################
export INGRESS_HOST=$(kubectl \
    get svc traefik \
    --namespace kube-system \
    -o=jsonpath='{$.status.loadBalancer.ingress[0].ip}')

####################################
# 3. Install ArgoCD in the cluster
####################################
helm repo add argo \
    https://argoproj.github.io/argo-helm

helm repo update

helm upgrade --install \
    argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --set server.ingress.hosts="{argo-cd.$INGRESS_HOST.nip.io}" \
    --set server.ingress.enabled=true \
    --set server.extraArgs="{--insecure}" \
    --set controller.args.appResyncPeriod=30 \
    --wait

export PASS=$(kubectl \
    --namespace argocd \
    get secret argocd-initial-admin-secret \
    --output jsonpath="{.data.password}" \
    | base64 --decode)

argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    argo-cd.$INGRESS_HOST.nip.io

argocd account update-password \
    --current-password $PASS \
    --new-password admin123

echo http://argo-cd.$INGRESS_HOST.nip.io
echo "admin:admin123"



# Shutdown
# k3d cluster delete mycluster