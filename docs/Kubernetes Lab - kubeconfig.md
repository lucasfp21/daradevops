# Kubernetes Lab — kubeconfig, portas do k3d e ArgoCD com Ingress

## 1. Entendendo o kubeconfig no k3d

Quando criamos um cluster com k3d:

```bash
k3d cluster create links
```

O k3d cria:

* containers Docker
* um cluster k3s dentro desses containers
* um load balancer
* um kubeconfig para acesso ao cluster

---

# 2. O que é kubeconfig?

O kubeconfig é o arquivo que o `kubectl` usa para saber:

* qual cluster acessar
* qual endpoint/API usar
* certificados
* usuário
* contexto atual

Comando:

```bash
kubectl config view
```

Exemplo:

```yaml
clusters:
- cluster:
    server: https://host.docker.internal:6550
```

---

# 3. O que é essa porta aleatória?

Exemplo:

```text
https://host.docker.internal:6550
```

Essa porta é:

```text
porta publicada pelo load balancer do k3d
```

Quando o cluster sobe, o k3d cria um container:

```text
k3d-links-serverlb
```

Esse container expõe a API do Kubernetes para o host Windows.

---

# 4. Fluxo real da conexão

```text
kubectl
   ↓
kubeconfig
   ↓
host.docker.internal:6550
   ↓
container k3d-links-serverlb
   ↓
API Server do Kubernetes
```

---

# 5. Por que a porta muda?

Quando recriamos o cluster:

```bash
k3d cluster delete links
k3d cluster create links
```

O Docker pode publicar outra porta aleatória:

```text
55348
64359
6550
51053
```

Então o kubeconfig antigo fica inválido.

---

# 6. Sintoma clássico

Erro:

```text
couldn't get current server API group list
```

ou:

```text
Unable to connect to the server
```

Normalmente significa:

* cluster recriado
* kubeconfig antigo
* porta mudou

---

# 7. Como corrigir

Em alguns casos, o `k3d kubeconfig merge` não atualiza corretamente o kubeconfig principal do Windows.

Então pode ser necessário editar manualmente o arquivo:

```text
C:/Users/<usuario>/.kube/config
```

ou substituir o conteúdo usando:

```bash
k3d kubeconfig get links
```

O ponto mais importante é atualizar:

```yaml
server: https://host.docker.internal:PORTA
```

Porque essa porta muda quando o cluster é recriado.

Exemplo:

Antes:

```yaml
server: https://host.docker.internal:51053
```

Depois:

```yaml
server: https://host.docker.internal:6550
```

Se o kubeconfig continuar apontando para a porta antiga:

```text
kubectl não consegue acessar o cluster
```

---

Atualizar o kubeconfig:

```bash
k3d kubeconfig merge links --kubeconfig-switch-context
```

ou:

```bash
k3d kubeconfig get links
```

Isso gera um kubeconfig novo com a porta correta.

---

# 8. Como validar

## Ver contexto atual

```bash
kubectl config current-context
```

Resultado esperado:

```text
k3d-links
```

---

## Testar conexão

```bash
kubectl get nodes
```

---

# 9. Entendendo o Ingress no k3d

No k3s existe um ingress controller padrão:

```text
Traefik
```

Ele é instalado automaticamente.

---

# 10. O que é um Ingress Controller?

É um reverse proxy dentro do Kubernetes.

Ele recebe tráfego HTTP/HTTPS e decide:

```text
para qual service enviar
```

---

# 11. Fluxo do tráfego

```text
Browser
   ↓
localhost:80
   ↓
k3d load balancer
   ↓
Traefik
   ↓
Ingress
   ↓
Service
   ↓
Pod
```

---

# 12. Por que precisamos publicar a porta 80?

Quando criamos o cluster:

```bash
k3d cluster create links \
  --servers 2 \
  --agents 2 \
  -p "80:80@loadbalancer"
```

Estamos dizendo:

```text
porta 80 do host Windows → porta 80 do load balancer do k3d
```

Sem isso:

* o ingress existe
* o Traefik funciona
* MAS o browser não consegue acessar

---

# 13. Como validar isso

```bash
docker ps
```

Resultado esperado:

```text
0.0.0.0:80->80/tcp
```

no container:

```text
k3d-links-serverlb
```

---

# 14. Hosts locais no Windows

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

Isso faz:

```text
hello.local → localhost
```

---

# 15. Como múltiplas apps usam a mesma porta 80?

O Traefik roteia pelo:

```text
Host header
```

Exemplo:

```text
http://nginx.local
```

envia:

```http
Host: nginx.local
```

Então o Traefik envia para o service correto.

---

# 16. Exemplo de ingress

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

# 17. Entendendo o problema do ArgoCD

O ArgoCD por padrão trabalha com HTTPS.

O service dele expõe:

```text
80
443
```

---

# 18. O problema clássico

Quando o ingress aponta para:

```yaml
number: 80
```

mas o ArgoCD força HTTPS interno,

podem ocorrer:

* redirects infinitos
* tela branca
* erro de conexão

---

# 19. Soluções possíveis

## Opção 1 — usar HTTPS do ArgoCD

Ingress:

```yaml
port:
  number: 443
```

Acesso:

```text
https://argocd.local
```

---

## Opção 2 — desabilitar HTTPS interno

Editar:

```bash
kubectl edit configmap argocd-cmd-params-cm -n argocd
```

Adicionar:

```yaml
data:
  server.insecure: "true"
```

Depois:

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

---

# 20. Qual abordagem é mais comum?

Em produção normalmente:

```text
TLS termina no ingress controller
```

Ou seja:

* Traefik
* NGINX
* Istio

fazem HTTPS.

E a aplicação trabalha apenas HTTP internamente.

---

# 21. Resumo geral

## kubeconfig

Responsável por:

* endpoint do cluster
* certificados
* autenticação
* contexto

---

## host.docker.internal

Ponte entre:

```text
Windows ↔ containers Docker
```

---

## k3d load balancer

Publica:

* API Kubernetes
* portas HTTP/HTTPS

---

## Traefik

Ingress controller do k3s.

Responsável pelo roteamento HTTP.

---

## Ingress

Define:

* hostname
* path
* service destino

---

## ArgoCD

GitOps controller.

Por padrão usa HTTPS interno.
