# 🧪 DevOps Home Lab

Ambiente de laboratório pessoal para estudo, prática e experimentação de conceitos de **DevOps, SRE e Cloud Computing**.

O objetivo é simular cenários do mundo real, aplicando boas práticas de infraestrutura, automação, observabilidade e confiabilidade de sistemas.

---

## 🎯 Objetivos

- Praticar **Infraestrutura como Código (IaC)**
- Simular ambientes distribuídos
- Trabalhar com **mensageria, containers e orquestração**
- Implementar práticas de **SRE (monitoramento, logs, resiliência)**
- Criar pipelines e automações reais
- Evoluir para arquitetura cloud-native

---

## 🧰 Tecnologias

### 🔧 Base
- Docker
- Kubernetes
- Linux

### ☁️ Cloud / Infra
- Terraform
- Ansible

### 📡 Mensageria
- IBM MQ / Kafka (futuro)

### 📊 Observabilidade
- Prometheus
- Grafana
- Loki

### 🔁 CI/CD
- GitHub Actions (ou Jenkins)

### 🗄️ Dados
- PostgreSQL
- Redis (futuro)

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