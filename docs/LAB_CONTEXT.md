# LAB_CONTEXT.md

# Projeto

Laboratório pessoal de Kubernetes + GitOps focado em:

- Kubernetes
- ArgoCD
- Helm
- GitOps
- Observabilidade
- Troubleshooting
- Estrutura profissional de repositório
- Ambientes locais com k3d

## Repositório

https://github.com/lucasfp21/daradevops

---

# Objetivos do laboratório

O laboratório foi criado para praticar:

- GitOps com ArgoCD
- Deploy automatizado via ApplicationSet
- Estruturação profissional de manifests
- Helm Charts
- Observabilidade com Prometheus e Grafana
- Troubleshooting Kubernetes
- Organização de ambientes
- Base para futuras evoluções:
  - CI/CD
  - Rollouts
  - Secrets
  - Multi-env
  - Service Mesh
  - Logging

---

# Stack atual

## Cluster

- k3d
- Kubernetes
- Traefik ingress controller padrão do k3s

---

## GitOps

- ArgoCD
- ApplicationSet

---

## Observabilidade

- kube-prometheus-stack
- Prometheus
- Grafana
- kube-state-metrics
- node-exporter

---

## Aplicação exemplo

- hello-python
- Deployment
- Service
- Ingress
- ConfigMap
- Secret

---

# Estrutura atual do repositório

```text
apps/
  hello-python/

bootstrap/
  applicationset-apps.yaml
  applicationset-platform.yaml
  argocd-cmd-params.yaml
  argocd-ingress.yaml

infra/
  ingress/
  namespaces/
  storage/

platform/
  monitoring/
    app.yaml
    values.yaml

lab/
docs/
scripts/

Arquitetura GitOps adotada

Fluxo principal:

GitHub
   ↓
ApplicationSet
   ↓
ArgoCD Applications
   ↓
Helm / Manifests
   ↓
Kubernetes
Padrão utilizado
Apps
apps/<app>/k8s

Aplicações simples com manifests Kubernetes puros.

Platform
platform/<service>

Serviços compartilhados do cluster:

monitoring
logging
cert-manager
ingress
etc
Infra
infra/

Infraestrutura base do cluster:

namespaces
storage
ingress
configs globais
Estrutura GitOps correta descoberta
ERRADO

ApplicationSet criando uma Application com o mesmo nome da Application interna.

Exemplo:

ApplicationSet -> monitoring
Application -> monitoring

Isso gerou:

self-management loop
OutOfSync infinito
nenhum pod criado
sync aparentemente saudável
CORRETO

Separar nomes:

ApplicationSet -> monitoring
Application Helm -> monitoring-stack

Fluxo final:

ApplicationSet platform
   ↓
Application monitoring
   ↓
Application monitoring-stack
   ↓
Helm kube-prometheus-stack
Problema importante resolvido
Caso crítico

O monitoring não subia mesmo aparecendo:

Healthy
OutOfSync

Sem pods no namespace monitoring.

Causa raiz
Application gerenciando ela mesma
loop de reconciliação do ArgoCD
Sintomas
namespace vazio
sem StatefulSets
sem PVCs
apenas Application aparecendo nos resources
Aprendizado
Healthy não significa funcional
verificar sempre:
pods
resources reais
events
árvore de Applications
Comandos úteis do laboratório
Verificar apps
kubectl get applications -n argocd
Verificar pods
kubectl get pods -A
Verificar monitoring
kubectl get pods -n monitoring
Descrever app
kubectl describe application monitoring -n argocd
Refresh forçado
kubectl annotate application monitoring `
  -n argocd `
  argocd.argoproj.io/refresh=hard --overwrite
Script de bootstrap atual

O laboratório possui automação para:

criar cluster k3d
configurar kubeconfig
instalar ArgoCD
habilitar insecure mode
aplicar ingress
aplicar ApplicationSets
iniciar ambiente completo
Hosts locais utilizados
Windows hosts file
C:\Windows\System32\drivers\etc\hosts
Entradas comuns
127.0.0.1 argocd.local
127.0.0.1 grafana.local
127.0.0.1 prometheus.local
127.0.0.1 hello.local
Convenções adotadas
GitOps

Tudo deve vir do Git.

Evitar:

kubectl edit
alterações manuais permanentes
drift
Organização

Separação clara entre:

infra
platform
apps
labs
Helm

Charts externos devem usar:

sources:

com:

ref: values

para values versionados no GitHub.

Próximos passos possíveis
Infra
cert-manager
external-dns
ingress-nginx alternativo
longhorn
metallb
Observabilidade
Loki
Promtail
Tempo
OpenTelemetry
Segurança
sealed-secrets
external-secrets
RBAC
network policies
GitOps avançado
AppProjects
environments/
overlays
multi-cluster
sync waves
CI/CD
GitHub Actions
build automático
push de imagens
image updater
Objetivo técnico final

Construir um laboratório local que simule práticas reais de:

Platform Engineering
DevOps
SRE
Cloud Native
GitOps Enterprise Patterns

com foco em aprendizado prático e troubleshooting real.