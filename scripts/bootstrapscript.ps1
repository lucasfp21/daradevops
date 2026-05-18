# setup.ps1

# Remove cluster antigo (opcional)
# k3d cluster delete links

Write-Host ""
Write-Host "=================================="
Write-Host "Criando cluster k3d..."
Write-Host "=================================="

k3d cluster create links `
  --servers 2 `
  --agents 2 `
  -p "80:80@loadbalancer" `
  -p "443:443@loadbalancer"

Write-Host ""
Write-Host "=================================="
Write-Host "Configurando kubeconfig..."
Write-Host "=================================="

k3d kubeconfig merge links --kubeconfig-switch-context

Write-Host ""
Write-Host "=================================="
Write-Host "Corrigindo kubeconfig..."
Write-Host "=================================="

(Get-Content "$HOME\.kube\config") `
  -replace 'host.docker.internal','127.0.0.1' |
  Set-Content "$HOME\.kube\config"

Write-Host ""
Write-Host "=================================="
Write-Host "Validando conexão com cluster..."
Write-Host "=================================="

kubectl cluster-info

Write-Host ""
Write-Host "=================================="
Write-Host "Criando namespace do ArgoCD..."
Write-Host "=================================="

kubectl create namespace argocd

Write-Host ""
Write-Host "=================================="
Write-Host "Instalando ArgoCD..."
Write-Host "=================================="

kubectl apply -n argocd `
  --server-side `
  --force-conflicts `
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host ""
Write-Host "=================================="
Write-Host "Aguardando ArgoCD subir..."
Write-Host "=================================="

kubectl wait `
  --for=condition=available `
  deployment/argocd-server `
  -n argocd `
  --timeout=300s

Write-Host ""
Write-Host "=================================="
Write-Host "Habilitando modo insecure..."
Write-Host "=================================="

kubectl patch configmap argocd-cmd-params-cm `
  -n argocd `
  --type merge `
  -p '{"data":{"server.insecure":"true"}}'

Write-Host ""
Write-Host "=================================="
Write-Host "Reiniciando argocd-server..."
Write-Host "=================================="

kubectl rollout restart deployment argocd-server -n argocd

kubectl rollout status deployment argocd-server `
  -n argocd `
  --timeout=300s

Write-Host ""
Write-Host "=================================="
Write-Host "Aplicando infraestrutura..."
Write-Host "=================================="

kubectl apply -f infra/namespaces/links.yaml

Write-Host ""
Write-Host "=================================="
Write-Host "Aplicando bootstrap GitOps..."
Write-Host "=================================="

kubectl apply -f bootstrap/argocd-ingress.yaml
kubectl apply -f bootstrap/applicationset.yaml

Write-Host ""
Write-Host "=================================="
Write-Host "Ambiente pronto!"
Write-Host "=================================="

Write-Host ""
Write-Host "ArgoCD:"
Write-Host "http://argocd.local"

Write-Host ""
Write-Host "Aplicações:"
Write-Host "http://hello.local"
Write-Host "http://nginx.local"