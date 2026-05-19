# 🚀 Recriação rápida do cluster k3d + ArgoCD

## 🧹 Remover cluster antigo

```bash
k3d cluster delete links
```

---

## ☸️ Criar novo cluster

```bash
k3d cluster create links \
  --servers 2 \
  --agents 2 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer"
```

---

## 🔌 Atualizar kubeconfig

```bash
k3d kubeconfig merge links --kubeconfig-switch-context
```

Validar:

```bash
kubectl get nodes
```

---

## ⚠️ Validar porta do kubeconfig

Verificar:

```bash
docker ps
```

Container esperado:

```text
k3d-links-serverlb
```

Porta esperada:

```text
0.0.0.0:6550->6443/tcp
```

Validar kubeconfig:

```bash
k3d kubeconfig get links
```

Se necessário editar:

```text
C:/Users/<usuario>/.kube/config
```

Garantir que:

```yaml
server: https://host.docker.internal:6550
```

---

## 🤖 Instalar ArgoCD

```bash
kubectl create namespace argocd
```

```bash
kubectl apply -n argocd \
  --server-side \
  --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 📁 Criar namespace das aplicações

```bash
kubectl create namespace links
```

---

## 🔁 Aplicar ApplicationSet

```bash
kubectl apply -f argocd/applicationset.yaml
```

---

## 🌐 Acessos

```text
http://hello.local
http://nginx.local
https://argocd.local
```
