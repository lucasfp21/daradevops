# setup.ps1

# Remove cluster antigo (opcional)
# k3d cluster delete links

Write-Host "Criando cluster k3d..."

k3d cluster create links `
  --servers 2 `
  --agents 2 `
  -p "80:80@loadbalancer" `
  -p "443:443@loadbalancer"

Write-Host "Configurando kubeconfig..."

k3d kubeconfig merge links --kubeconfig-switch-context

Write-Host "Criando namespace do ArgoCD..."

kubectl create namespace argocd

Write-Host "Instalando ArgoCD..."

kubectl apply -n argocd `
  --server-side `
  --force-conflicts `
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "Aguardando ConfigMap do ArgoCD..."

do {
    Start-Sleep -Seconds 2
    $cm = kubectl get configmap argocd-cmd-params-cm -n argocd --ignore-not-found
} while (-not $cm)

Write-Host "Habilitando modo insecure do ArgoCD..."

kubectl patch configmap argocd-cmd-params-cm `
  -n argocd `
  --type merge `
  -p '{"data":{"server.insecure":"true"}}'

Write-Host "Reiniciando argocd-server..."

kubectl rollout restart deployment argocd-server -n argocd

kubectl rollout status deployment argocd-server `
  -n argocd `
  --timeout=300s

Write-Host "Aplicando bootstrap..."

kubectl apply -f bootstrap/argocd-ingress.yaml
kubectl apply -f bootstrap/applicationset.yaml

Write-Host "Aplicando infraestrutura..."

kubectl apply -f infra/namespaces/links.yaml

Write-Host ""
Write-Host "Ambiente pronto!"
Write-Host "ArgoCD: http://argocd.local"
Write-Host "Apps:"
Write-Host " - http://hello.local"
Write-Host " - http://nginx.local"