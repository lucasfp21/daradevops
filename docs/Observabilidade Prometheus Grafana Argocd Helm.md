# 📊 Observabilidade com Prometheus + Grafana via ArgoCD e Helm

## 🎯 Objetivo

Adicionar uma stack de observabilidade ao cluster Kubernetes utilizando:

* Prometheus
* Grafana
* Helm Chart
* ArgoCD
* GitOps

A ideia é permitir monitoramento do cluster, pods, nodes e aplicações de forma automatizada e declarativa.

---

# 🧠 Conceitos

## Prometheus

Responsável por coletar métricas do cluster Kubernetes.

Exemplos:

* CPU
* Memória
* Status dos pods
* Uso de disco
* Métricas do Kubernetes

---

## Grafana

Interface visual para dashboards.

Usaremos o Grafana para visualizar métricas do Prometheus.

---

## Helm

Gerenciador de pacotes Kubernetes.

Ao invés de instalar dezenas de YAMLs manualmente, usamos um Helm Chart.

---

## ArgoCD + Helm

O ArgoCD consegue instalar Helm Charts automaticamente.

Fluxo:

```text
Git
↓
ArgoCD
↓
Helm Chart
↓
Kubernetes
```

---

# 📁 Estrutura utilizada

```text
infra/
└── monitoring/
    ├── namespace.yaml
    ├── application.yaml
    ├── grafana-ingress.yaml
    └── prometheus-ingress.yaml
```

---

# 1️⃣ Criar namespace

Arquivo:

```text
infra/monitoring/namespace.yaml
```

Conteúdo:

```yaml
apiVersion: v1
kind: Namespace

metadata:
  name: monitoring
```

Aplicar:

```powershell
kubectl apply -f infra/monitoring/namespace.yaml
```

---

# 2️⃣ Criar Application do ArgoCD

Arquivo:

```text
infra/monitoring/application.yaml
```

Conteúdo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application

metadata:
  name: monitoring
  namespace: argocd

spec:
  project: default

  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 69.8.2

    helm:
      releaseName: monitoring

  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring

  syncPolicy:
    automated:
      prune: true
      selfHeal: true

    syncOptions:
      - CreateNamespace=true
```

---

# 🧠 O que esse Application faz

O ArgoCD:

```text
Baixa o Helm Chart
↓
Renderiza os manifests
↓
Aplica no cluster
↓
Mantém sincronizado
```

Tudo automaticamente.

---

# 3️⃣ Aplicar o Application

```powershell
kubectl apply -f infra/monitoring/application.yaml
```

---

# 4️⃣ Validar instalação

Verificar aplicações do ArgoCD:

```powershell
kubectl get applications -n argocd
```

Resultado esperado:

```text
monitoring
```

---

# 5️⃣ Verificar pods

```powershell
kubectl get pods -n monitoring
```

A stack sobe vários componentes.

Exemplos:

* grafana
* prometheus
* alertmanager
* operator
* kube-state-metrics
* node-exporter

A primeira instalação pode demorar alguns minutos.

---

# 6️⃣ Criar ingress do Grafana

Arquivo:

```text
infra/monitoring/grafana-ingress.yaml
```

Conteúdo:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: grafana
  namespace: monitoring

spec:
  ingressClassName: traefik

  rules:
    - host: grafana.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: monitoring-grafana
                port:
                  number: 80
```

Aplicar:

```powershell
kubectl apply -f infra/monitoring/grafana-ingress.yaml
```

---

# 7️⃣ Criar ingress do Prometheus

Arquivo:

```text
infra/monitoring/prometheus-ingress.yaml
```

Conteúdo:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: prometheus
  namespace: monitoring

spec:
  ingressClassName: traefik

  rules:
    - host: prometheus.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: monitoring-kube-prometheus-prometheus
                port:
                  number: 9090
```

Aplicar:

```powershell
kubectl apply -f infra/monitoring/prometheus-ingress.yaml
```

---

# 8️⃣ Atualizar hosts do Windows

Editar:

```text
C:\Windows\System32\drivers\etc\hosts
```

Adicionar:

```text
127.0.0.1 grafana.local
127.0.0.1 prometheus.local
```

---

# 9️⃣ Acessar interfaces

## Grafana

```text
http://grafana.local
```

---

## Prometheus

```text
http://prometheus.local
```

---

# 🔐 Senha inicial do Grafana

Usuário:

```text
admin
```

Senha:

```powershell
kubectl get secret monitoring-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

---

# 📊 O que já é possível visualizar

* CPU
* Memória
* Nodes
* Pods
* Deployments
* Uso do cluster
* Métricas do Kubernetes

---

# 🧠 Conceitos importantes aprendidos

## GitOps

Toda infraestrutura declarada em Git.

---

## ArgoCD

Responsável por reconciliar o estado do cluster.

---

## Helm

Instala aplicações complexas usando charts.

---

## Kubernetes Operators

O kube-prometheus-stack utiliza Operators para gerenciamento automático de recursos.

---

# 🚀 Próximos passos

Sugestões para evolução do lab:

* Loki
* Promtail
* Alertmanager
* Requests/Limits
* HPA
* Certificados TLS
* External Secrets
* Vault
* Terraform
