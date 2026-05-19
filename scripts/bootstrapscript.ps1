# ==================================
# setup.ps1
# Cluster Bootstrap GitOps
# ==================================

# ----------------------------------
# CONFIG
# ----------------------------------

$CLUSTER_NAME = "links"

# ----------------------------------
# CLEANUP (optional)
# ----------------------------------

# k3d cluster delete $CLUSTER_NAME

Write-Host ""
Write-Host "=================================="
Write-Host "CRIANDO CLUSTER K3D"
Write-Host "=================================="

k3d cluster create $CLUSTER_NAME `
  --servers 2 `
  --agents 2 `
  -p "80:80@loadbalancer" `
  -p "443:443@loadbalancer"

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "ERRO AO CRIAR CLUSTER"
  exit 1
}

# ----------------------------------
# KUBECONFIG
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "CONFIGURANDO KUBECONFIG"
Write-Host "=================================="

k3d kubeconfig merge $CLUSTER_NAME --kubeconfig-switch-context

Write-Host ""
Write-Host "=================================="
Write-Host "CORRIGINDO HOST.DOCKER.INTERNAL"
Write-Host "=================================="

(Get-Content "$HOME\.kube\config") `
  -replace 'host.docker.internal','127.0.0.1' |
  Set-Content "$HOME\.kube\config"

# ----------------------------------
# VALIDATION
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "VALIDANDO CLUSTER"
Write-Host "=================================="

kubectl cluster-info

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "ERRO AO CONECTAR NO CLUSTER"
  exit 1
}

# ----------------------------------
# INFRA
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "APLICANDO INFRAESTRUTURA BASE"
Write-Host "=================================="

kubectl apply -f infra/namespaces/
kubectl apply -f infra/storage/
kubectl apply -f infra/ingress/

# ----------------------------------
# ARGOCD INSTALL
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "INSTALANDO ARGOCD"
Write-Host "=================================="

kubectl apply -n argocd `
  --server-side `
  --force-conflicts `
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "ERRO AO INSTALAR ARGOCD"
  exit 1
}

# ----------------------------------
# WAIT ARGOCD
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "AGUARDANDO ARGOCD"
Write-Host "=================================="

kubectl wait `
  --for=condition=available `
  deployment/argocd-server `
  -n argocd `
  --timeout=300s

kubectl wait `
  --for=condition=available `
  deployment/argocd-repo-server `
  -n argocd `
  --timeout=300s

kubectl wait `
  --for=condition=available `
  deployment/argocd-application-controller `
  -n argocd `
  --timeout=300s

# ----------------------------------
# ARGOCD INSECURE
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "CONFIGURANDO ARGOCD"
Write-Host "=================================="

kubectl apply -f bootstrap/argocd-cmd-params.yaml

Write-Host ""
Write-Host "=================================="
Write-Host "REINICIANDO ARGOCD SERVER"
Write-Host "=================================="

kubectl rollout restart deployment argocd-server -n argocd

kubectl rollout status deployment argocd-server `
  -n argocd `
  --timeout=300s

# ----------------------------------
# GITOPS BOOTSTRAP
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "APLICANDO BOOTSTRAP GITOPS"
Write-Host "=================================="

kubectl apply -f bootstrap/argocd-ingress.yaml

kubectl apply -f bootstrap/applicationset-apps.yaml

kubectl apply -f bootstrap/applicationset-platform.yaml

# ----------------------------------
# FINAL
# ----------------------------------

Write-Host ""
Write-Host "=================================="
Write-Host "AMBIENTE PRONTO"
Write-Host "=================================="

Write-Host ""
Write-Host "ARGOCD"
Write-Host "http://argocd.local"

Write-Host ""
Write-Host "APPS"
Write-Host "http://hello.local"

Write-Host ""
Write-Host "PLATFORM"
Write-Host "http://grafana.local"
Write-Host "http://prometheus.local"

Write-Host ""
Write-Host "TRAEFIK"
Write-Host "http://traefik.local"

Write-Host ""
Write-Host "=================================="
Write-Host "LOGIN GRAFANA"
Write-Host "user: admin"
Write-Host "password: admin123"
Write-Host "=================================="