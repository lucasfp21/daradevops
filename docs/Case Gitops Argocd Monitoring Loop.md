# Case — Debug de GitOps com ArgoCD + Helm + ApplicationSet

## Contexto

O ambiente utilizava:

* k3d
* Kubernetes
* ArgoCD
* ApplicationSet
* Helm
* kube-prometheus-stack

Estrutura simplificada do repositório:

```text
platform/
  monitoring/
    app.yaml
    values.yaml
```

O objetivo era:

```text
ApplicationSet
   ↓
Application monitoring
   ↓
Helm chart kube-prometheus-stack
```

---

# Sintoma do problema

O ArgoCD mostrava:

```text
monitoring   OutOfSync   Healthy
```

Mas:

```powershell
kubectl get pods -n monitoring
```

retornava:

```text
No resources found
```

Ou seja:

* a aplicação existia
* não havia erro explícito
* porém nenhum recurso era criado

---

# O erro real

O problema era um loop de gerenciamento.

O `ApplicationSet` criava uma aplicação chamada:

```yaml
metadata:
  name: monitoring
```

E dentro de `platform/monitoring/app.yaml` existia outra aplicação com o MESMO nome:

```yaml
metadata:
  name: monitoring
```

Resultado:

```text
ApplicationSet
   ↓
Application monitoring
   ↓
Application monitoring
   ↓
Application monitoring
```

A aplicação tentava gerenciar ela mesma.

Isso gerava:

* loop de reconciliação
* OutOfSync infinito
* nenhum recurso Helm criado
* ausência total de pods

---

# Por que foi difícil detectar

Esse erro é difícil porque:

## 1. O ArgoCD não falha claramente

A aplicação aparecia como:

```text
Healthy
```

Isso confunde.

O ArgoCD considerava o objeto `Application` saudável.

Mas o conteúdo interno nunca era reconciliado corretamente.

---

## 2. Não havia eventos críticos

Os eventos mostravam:

```text
successfully synced
```

Mas o sync era apenas da própria `Application`.

Não do Helm chart.

---

## 3. O namespace estava vazio

Isso indicava:

* o Helm nunca executou
* o chart nunca foi instalado
* o problema estava antes da camada Helm

Esse foi o principal indicador.

---

# Como detectar esse tipo de problema no futuro

## Checklist rápido

## 1. Existe pod criado?

```powershell
kubectl get pods -A
```

Se nada foi criado:

* o Helm pode não ter executado
* o Application pode estar errado
* o path pode estar incorreto

---

## 2. O Application mostra resources reais?

```powershell
kubectl get application monitoring -n argocd -o yaml
```

Verifique:

```yaml
status:
  resources:
```

Se aparecer apenas:

```yaml
kind: Application
name: monitoring
```

Então a app está gerenciando apenas outra app.

E não workloads reais.

---

## 3. Validar nome das Applications

Nunca use:

```text
ApplicationSet -> monitoring
Application interna -> monitoring
```

Sempre use nomes diferentes.

Exemplo correto:

```text
ApplicationSet -> monitoring
Application Helm -> monitoring-stack
```

---

## 4. Verificar path do ApplicationSet

Errado:

```yaml
path: '{{path}}'
```

quando a pasta contém apenas outra Application.

Correto:

* usar estrutura clara
* separar wrapper app da app Helm
* evitar aplicações recursivas

---

# Estrutura final correta

```text
platform/
  monitoring/
    app.yaml
    values.yaml
```

## app.yaml

```yaml
metadata:
  name: monitoring-stack
```

## ApplicationSet

```yaml
metadata:
  name: platform
```

Resultado:

```text
ApplicationSet platform
   ↓
Application monitoring
   ↓
Application monitoring-stack
   ↓
Helm chart
```

---

# Aprendizados

## 1. Healthy não significa funcional

Uma app pode estar:

```text
Healthy + OutOfSync
```

E ainda assim não criar nada.

---

## 2. Namespace vazio é pista importante

Se:

```powershell
kubectl get pods -n monitoring
```

não retorna nada:

* o problema está antes do Kubernetes workload
* geralmente em GitOps/Helm/Application

---

## 3. Loops de Application são perigosos

Evite:

* Application gerenciando ela mesma
* nomes iguais
* paths recursivos

---

# Estado final

Após corrigir:

* Grafana subiu
* Prometheus subiu
* kube-state-metrics subiu
* node-exporter subiu
* ArgoCD sincronizou corretamente

Fluxo final:

```text
GitHub
   ↓
ApplicationSet
   ↓
ArgoCD Application
   ↓
Helm Chart
   ↓
Kubernetes Resources
```
