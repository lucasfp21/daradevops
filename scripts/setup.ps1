# setup.ps1

# k3d cluster delete links

k3d cluster create links `
  --servers 2 `
  --agents 2 `
  -p "80:80@loadbalancer" `
  -p "443:443@loadbalancer"

k3d kubeconfig merge links --kubeconfig-switch-context

kubectl create namespace argocd
kubectl create namespace links

Write-Host "Instalando ArgoCD..."

kubectl apply -n argocd `
  --server-side `
  --force-conflicts `
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl apply -f argocd/ingress.yaml
kubectl apply -f argocd/applicationset.yaml

Write-Host "Aguardando ArgoCD subir..."
kubectl wait --for=condition=available `
  deployment/argocd-server `
  -n argocd `
  --timeout=300s

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

