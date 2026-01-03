---
layout: post
title: "Do Caos à Ordem: O que aprendi reconstruindo meu homelab do zero"
lang: pt-br
slug: from-chaos-to-order-homelab-rebuild
date: 2025-12-28 10:00:00 +0800
categories: [Infrastructure & DevOps, Self-Hosting]
tags: [homelab, docker, InfrastructureAsCode, traefik, observability, selfhosting]
---

# Do Caos à Ordem: A evolução do meu homelab (r2d2)

A maioria das jornadas com homelabs começa com um pouco de hardware sobrando e uma dose saudável de curiosidade técnica. A minha remonta a 2016, envolvendo um Raspberry Pi modelo B+ que sobreviveu milagrosamente à queda fatal de um drone DIY. O que começou como um simples projeto Pi-hole eventualmente evoluiu para a espinha dorsal do ecossistema que hoje chamo de **r2d2**.
## A evolução do hardware: Onde I/O é rei 👑

Muitas pessoas começam com um Raspberry Pi, mas logo encontram o mesmo obstáculo que eu: limitações de I/O e processamento. Tentar rodar uma stack de servidor de mídia (Plex + os "arr's") via USB 2.0 e um processador ARM antigo é impossível.

Após a "luz vermelha da morte" do meu Raspberry, migrei para um PC herdado (AMD de 2 núcleos, 8GB de RAM). Foi meu laboratório do mundo real para Docker e volumes, mas 8GB de RAM rapidamente se tornaram um gargalo para os mais de 15 contêineres em execução.

A configuração atual: Hoje, rodo o homelab em um i5 de 3ª geração (4 núcleos) com 16GB de RAM DDR3 e o fiel HD de 1TB herdado. Para um laboratório de estudos e serviços domésticos, este é o "ponto ideal": hardware barato, mas com virtualização e RAM suficientes para rodar instâncias do Postgres e clusters K8s (usando kind) sem sobrecarregar a CPU.

## O incidente: Por que "configurar e esquecer" é um risco

No início de 2025, aprendi da maneira mais difícil que automação sem observabilidade é uma dívida técnica.

Eu usava o `watchtower` para atualizar imagens Docker automaticamente. Configurei via `docker run` e esqueci. O problema? Ele não limpava as imagens antigas. Combinado com o cache de metadados do servidor de mídia, o HD atingiu 100% de capacidade. O servidor Ubuntu entrou em colapso. Para evitar outro apocalipse de disco cheio, abandonei o `docker run` padrão e integrei o Watchtower ao meu compose de gerenciamento com flags de limpeza explícitas:
```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_POLL_INTERVAL=86400 # Verificar uma vez por dia
```
Isso garante que imagens antigas sejam removidas imediatamente após o download de uma nova, mantendo o uso de armazenamento enxuto.

Tentei uma "recuperação de desastre" usando ferramentas de dump para gerar arquivos Compose, mas o resultado foi um YAML monolítico de 1.000 linhas — insustentável e frágil. Lição aprendida: se você não pode versionar sua infraestrutura, você não tem uma infraestrutura; você tem um castelo de cartas.

## Arquitetura da informação: Infra as Code (interno)

Após o colapso, decidi que a reconstrução seria estruturada. Criei um repositório no Github и organizei meus `docker-compose` por contexto (escopos). Isso torna o backup, a migração e a solução de problemas muito mais fáceis.

Uma decisão de arquitetura que tomei durante a migração foi usar estritamente **Bind Mounts** em vez de Volumes Nomeados para serviços stateful. Isso me permite manter todos os arquivos de configuração e dados de banco de dados em um diretório estruturado `/opt/homelab/config`, que é muito mais fácil de fazer backup via `rsync` ou `restic` do que lidar com o armazenamento de volume interno do Docker.
### 1. Rede e DX local (Traefik + Pi-Hole)

A maior virada de jogo foi abandonar o `IP:porta` para usar domínios reais.

- **Pi-Hole**: Atua como meu servidor DNS interno.
- **Traefik**: Como um Proxy Reverso, escuta o socket do Docker e resolve os nomes. Hoje, em vez de memorizar combinações de portas obscuras, acesso `portainer.r2d2` ou `pihole.r2d2`. É um ganho enorme na Experiência do Desenvolvedor (DX) em casa.

A beleza do Traefik está em seu **Docker Provider**. Ao expor o socket do Docker (de forma segura através de um proxy em uma iteração futura), os serviços se registram via labels. Chega de edições manuais de upstream no Nginx:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.portainer.rule=Host(`portainer.r2d2`)"
  - "traefik.http.services.portainer.loadbalancer.server.port=9000"
```
Combinado com um registro DNS curinga no Pi-hole apontando para o IP do host, o fluxo de trabalho para iniciar um novo serviço agora é totalmente declarativo.
### 2. Servidor de mídia e automação de conteúdo

A stack clássica (Radarr, Sonarr, Bazarr, Prowlarr + Plex) lida com meu consumo de conteúdo. Recentemente, adicionei o **Overseerr**, que centraliza todas as solicitações em uma interface moderna. Tudo é baixado usando o **qBitorrent** e organizado automaticamente. Mantenho um limite de qualidade de 1080p (em alguns casos uso 4k, mas apenas em casos especiais) devido a restrições de espaço — um compromisso consciente entre qualidade e espaço em disco.

### 3. Produtividade e "Nuvem" Privada

- **Syncthing**: Minha alternativa ao Obsidian Sync. Sincroniza meu cofre de anotações em tempo real entre meus dispositivos, sem custos e sem que os dados saiam da minha rede.
- **Paperless-ngx**: Meu arquivo digital. Uso para OCR de faturas e documentos, transformando meu homelab em um servidor de arquivos inteligente.
- **Stirling PDF**: Essencial para manipular PDFs localmente, eliminando a necessidade de usar ferramentas de terceiros duvidosas. (~~ilovepdf~~)

---

## O Futuro: LLMs e Observabilidade

Com o erro de disco para trás, agora estou rodando uma stack **Prometheus + Grafana** para monitorar recursos. Além disso, comecei a explorar o Open Web-UI. Ele permite o uso de APIs de LLM (Pay-as-you-go) ou até mesmo a execução de modelos locais através do Ollama, garantindo total privacidade para dados proprietários ou sensíveis.

Meu homelab não é uma tentativa de abandonar os serviços em nuvem, mas sim um playground de engenharia. É o lugar onde posso cometer erros, quebrar a produção e aprender sobre resiliência sem queimar o orçamento da empresa.
