# 🧪 DevOps Home Lab

Ambiente de laboratório pessoal para estudo, prática e experimentação de conceitos de **DevOps, SRE e Cloud Computing**.

O objetivo é simular cenários do mundo real, aplicando boas práticas de infraestrutura, automação, observabilidade e confiabilidade de sistemas.

---

## 🎯 Objetivos

* Praticar **Infraestrutura como Código (IaC)**
* Simular ambientes distribuídos
* Trabalhar com **mensageria, containers e orquestração**
* Implementar práticas de **SRE (monitoramento, logs, resiliência)**
* Criar pipelines e automações reais
* Evoluir para arquitetura cloud-native
* Implementar práticas de GitOps
* Simular arquitetura moderna baseada em Kubernetes

---

## 🧰 Tecnologias

### 🔧 Base

* Docker
* Kubernetes
* k3d
* kubectl
* Linux

### ☁️ Cloud / Infra

* Terraform
* Ansible

### 📡 Mensageria

* IBM MQ / Kafka (futuro)

### 📊 Observabilidade

* Prometheus
* Grafana
* Loki

### 🔁 CI/CD / GitOps

* GitHub Actions (ou Jenkins)
* ArgoCD
* ApplicationSet

### 🌐 Networking

* Traefik Ingress Controller
* Kubernetes Ingress

### 🗄️ Dados

* PostgreSQL
* Redis (futuro)

---

## 🧠 Arquitetura (em evolução)

```text
        +---------------------+
        |     CI/CD Pipeline  |
        +----------+----------+
                   |
                   v
        +---------------------+
        |   Kubernetes Cluster|
        +----------+----------+
                   |
     +-------------+-------------+
     |                           |
     v                           v
[ Microservices ]        [ Messaging (MQ) ]
     |                           |
     v                           v
[ Database ]             [ Event Consumers ]
```

---

# ☸️ Kubernetes Lab

O ambiente utiliza:

* Kubernetes via k3s
* Cluster local criado com k3d
* Múltiplos nodes
* Ingress Controller
* GitOps com ArgoCD

---

## 🚀 Cluster k3d

Criação do cluster:

```bash
k3d cluster create links \
  --servers 2 \
  --agents 2 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer"
```

---

## 📦 Estrutura do cluster

```text
+----------------------+
|     Host Windows     |
+----------+-----------+
           |
           v
+----------------------+
|   k3d Load Balancer  |
+----------+-----------+
           |
           v
+----------------------+
|     Traefik Ingress  |
+----------+-----------+
           |
     +-----+-----+
     |           |
     v           v
 hello.local   nginx.local
```

---

## 🔌 kubeconfig

O `kubectl` acessa o cluster através do kubeconfig.

Exemplo:

```yaml
server: https://host.docker.internal:6550
```

Essa porta é publicada automaticamente pelo load balancer do k3d.

Quando o cluster é recriado, a porta pode mudar.

Caso isso aconteça:

```bash
k3d kubeconfig merge links --kubeconfig-switch-context
```

ou:

```bash
k3d kubeconfig get links
```

Em alguns casos pode ser necessário atualizar manualmente:

```text
C:/Users/<usuario>/.kube/config
```

---

## 🌐 Ingress Controller

O cluster utiliza o:

```text
Traefik
```

como Ingress Controller padrão do k3s.

Responsável por:

* roteamento HTTP
* exposição de aplicações
* host routing
* reverse proxy

---

## 📍 Ingress

As aplicações são acessadas através de domínios locais.

Exemplo:

```text
http://hello.local
http://nginx.local
http://argocd.local
```

---

## 🖥️ Hosts local do Windows

Arquivo:

```text
C:\Windows\System32\drivers\etc\hosts
```

Exemplo:

```text
127.0.0.1 hello.local
127.0.0.1 nginx.local
127.0.0.1 argocd.local
```

---

## 📄 Exemplo de Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: nginx-app
  namespace: links

spec:
  ingressClassName: traefik

  rules:
  - host: nginx.local

    http:
      paths:
      - path: /
        pathType: Prefix

        backend:
          service:
            name: nginx-app
            port:
              number: 80
```

---

# 🤖 ArgoCD

O ambiente utiliza GitOps com ArgoCD.

O ArgoCD é responsável por:

* sincronizar manifests Kubernetes
* automatizar deploys
* manter estado desejado
* detectar drift de configuração

---

## 🚀 Instalação do ArgoCD

```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  --server-side \
  --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## 🌐 Ingress do ArgoCD

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: argocd
  namespace: argocd

spec:
  ingressClassName: traefik

  rules:
  - host: argocd.local

    http:
      paths:
      - path: /
        pathType: Prefix

        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

Acesso:

```text
https://argocd.local
```

---

## 🔑 Senha inicial do ArgoCD

PowerShell:

```powershell
[System.Text.Encoding]::UTF8.GetString(
  [System.Convert]::FromBase64String(
    (kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}")
  )
)
```

Usuário:

```text
admin
```

---

# 🔁 GitOps com ApplicationSet

O ambiente utiliza:

```text
ApplicationSet
```

para descoberta automática de aplicações.

---

## 📁 Estrutura esperada

```text
apps/
 ├── hello-python/
 │    └── k8s/
 ├── nginx/
 │    └── k8s/
```

---

## 📄 ApplicationSet

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet

metadata:
  name: apps
  namespace: argocd

spec:
  generators:
  - git:
      repoURL: https://github.com/lucasfp21/daradevops.git
      revision: HEAD
      directories:
      - path: apps/*

  template:
    metadata:
      name: '{{path.basename}}'

    spec:
      project: default

      source:
        repoURL: https://github.com/lucasfp21/daradevops.git
        targetRevision: HEAD
        path: '{{path}}/k8s'

      destination:
        server: https://kubernetes.default.svc
        namespace: links

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

---

## 🔄 Fluxo GitOps

```text
Git Push
    ↓
GitHub Repository
    ↓
ArgoCD
    ↓
Kubernetes Cluster
    ↓
Deploy automático
```

---

# 🐳 Aplicações do laboratório

## 🐍 hello-python

Aplicação Python simples utilizada para:

* testes de deployment
* services
* ingress
* ConfigMap
* Secret
* GitOps

---

## 🌐 nginx-app

Aplicação NGINX utilizada para:

* testes de ingress
* roteamento HTTP
* exposição de serviços

---

# 📚 Conceitos praticados

* Docker
* Build de imagens
* Docker Hub
* Kubernetes
* Deployments
* ReplicaSets
* Pods
* Services
* ConfigMap
* Secrets
* Ingress
* Ingress Controller
* Traefik
* GitOps
* ArgoCD
* ApplicationSet
* DNS local
* Reverse Proxy
* Cluster HA
* k3d
* k3s

---

# 🚧 Próximos passos

* Prometheus
* Grafana
* Loki
* Helm
* Terraform
* Ansible
* Kafka
* IBM MQ
* Cert-Manager
* HTTPS/TLS
* GitHub Actions
* Observabilidade
