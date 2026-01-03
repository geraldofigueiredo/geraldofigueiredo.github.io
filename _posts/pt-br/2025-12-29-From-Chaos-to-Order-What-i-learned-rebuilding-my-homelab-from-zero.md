---
layout: post
title:  "Do Caos à Ordem: O que aprendi reconstruindo meu homelab do zero"
date:   2025-12-29 00:00:00 +0000
categories: homelab docker
lang: pt-br
---

# Do Caos à Ordem: A evolução do meu homelab (r2d2)
A maioria das jornadas de um homelab começa com um pouco de hardware sobressalente e uma boa dose de curiosidade técnica. A minha remonta a 2016, envolvendo um Raspberry Pi modelo B+ que sobreviveu milagrosamente à queda fatal de um drone DIY. O que começou como um simples projeto de Pi-hole acabou evoluindo para a espinha dorsal do ecossistema que hoje chamo de r2d2.

## Evolução do hardware: Onde o I/O é rei 👑
Muita gente começa com um Raspberry Pi, mas logo atinge o mesmo limite que eu: restrições de I/O e processamento. Tentar rodar uma stack de media server (Plex + os "Arrs") via USB 2.0 e um processador ARM antigo é impossível.

Após a "luz vermelha da morte" do meu Raspberry, mudei para um PC herdado (AMD 2-cores, 8GB RAM). Foi meu laboratório de mundo real de Docker e volumes, mas os 8GB de RAM rapidamente se tornaram um gargalo para os mais de 15 containers rodando (e aumentando).

O setup atual: Hoje, rodo o homelab usando um i5 de 3ª geração (4 núcleos) com 16GB de RAM DDR3 e o leal HD de 1TB herdado. Para um laboratório de estudos e serviços domésticos, este é o "ponto de equilíbrio ideal": hardware barato, mas com virtualização e RAM suficientes para rodar instâncias de Postgres e clusters K8s (usando Kind) sem fritar a CPU.

## O incidente: Por que "Configurar e Esquecer" é um risco
No início de 2025, aprendi da maneira mais difícil que automação sem observabilidade é dívida técnica.

Eu estava rodando o watchtower para atualizar as imagens do Docker automaticamente. Configurei via docker run e esqueci. O problema? Ele não estava limpando as imagens antigas. Somado ao cache de metadados do media server, o HDD atingiu 100% de capacidade. O servidor Ubuntu colapsou. Para evitar outro "apocalipse de disco cheio", abandonei o docker run padrão e integrei o Watchtower ao meu Compose de gerenciamento com flags explícitas de limpeza:
```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_POLL_INTERVAL=86400 # Verifica uma vez por dia
```
Isso garante que as imagens antigas sejam removidas imediatamente após o download de uma nova, mantendo o uso de armazenamento enxuto.

Tentei um "disaster recovery" usando ferramentas de dump para gerar arquivos Compose, mas o resultado foi um YAML monolítico de 1.000 linhas — insustentável e frágil. Lição aprendida: se você não consegue versionar sua infra, você não tem uma infraestrutura; você tem um castelo de cartas.

## Arquitetura de informação: Infra como Código (interna)
Após o colapso, decidi que a reconstrução seria estruturada. Criei um repositório no GitHub e organizei meus docker-compose por contexto (escopos). Isso torna o backup, a migração e o troubleshooting muito mais fáceis.

Uma decisão arquitetural que tomei durante a migração foi usar estritamente Bind Mounts em vez de Named Volumes para serviços com estado (stateful). Isso me permite manter todos os arquivos de configuração e dados de bancos de dados em um diretório estruturado /opt/homelab/config, que é muito mais fácil de salvar via rsync ou restic do que lidar com o armazenamento interno de volumes do Docker.

### 1. Networking e DX local (Traefik + Pi-Hole)
A maior mudança de jogo foi abandonar o padrão IP:porta por domínios reais.

Pi-Hole: Atua como meu servidor DNS interno.

Traefik: Como Reverse Proxy, escuta o socket do Docker e resolve os nomes. Hoje, em vez de memorizar combinações obscuras de portas, acesso portainer.r2d2 ou pihole.r2d2. É um ganho enorme de Developer Experience (DX) dentro de casa.

A beleza do Traefik reside no seu Docker Provider. Ao expor o socket do Docker (de forma segura via proxy em uma iteração futura), os serviços se registram via labels. Chega de edições manuais de upstream no Nginx:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.portainer.rule=Host(`portainer.r2d2`)"
  - "traefik.http.services.portainer.loadbalancer.server.port=9000"
```
Combinado com um registro DNS wildcard no Pi-hole apontando para o IP do host, o workflow para subir um novo serviço agora é totalmente declarativo.

### 2. Media server e automação de conteúdo
A stack clássica (Radarr, Sonarr, Bazarr, Prowlarr + Plex) cuida do meu consumo de conteúdo. Recentemente, adicionei o Overseerr, que centraliza todos os pedidos em uma interface moderna. Tudo é baixado usando qBitorrent e organizado automaticamente. Mantenho um limite de qualidade de 1080p (em alguns casos uso 4k, mas apenas casos especiais) devido a restrições de espaço — um trade-off consciente entre qualidade e espaço em disco.

### 3. Produtividade e "Nuvem" Privada
Syncthing: Minha alternativa ao Obsidian Sync. Sincroniza meu cofre de notas em tempo real entre meus dispositivos, sem custos e sem que os dados saiam da minha rede.

Paperless-ngx: Meu arquivo digital. Uso para OCR de faturas e documentos, transformando meu homelab em um servidor de arquivos inteligente.

Stirling PDF: Essencial para manipular PDFs localmente, eliminando a necessidade de usar ferramentas de terceiros duvidosas (~~ilovepdf~~).

## O Futuro: LLMs e Observabilidade
Com os erros de disco no passado, agora estou rodando uma stack de Prometheus + Grafana para monitorar recursos. Além disso, comecei a explorar o Open Web-UI. Ele permite o uso de APIs de LLM (Pay-as-you-go) ou até mesmo rodar modelos locais através do Ollama, garantindo total privacidade para dados proprietários ou sensíveis.

Meu homelab não é uma tentativa de abandonar os serviços em nuvem, mas sim um playground de engenharia. É o lugar onde posso cometer erros, quebrar a produção e aprender sobre resiliência sem queimar o orçamento da empresa.
