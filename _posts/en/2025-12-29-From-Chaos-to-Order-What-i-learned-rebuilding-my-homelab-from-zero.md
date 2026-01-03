---
layout: post
title: From Chaos to Order What I learned rebuilding my homelab from zero
date: 2025-12-28 10:00:00 +0800
categories: [Infrastructure & DevOps, Self-Hosting]
tags: [homelab, docker, InfrastructureAsCode, traefik, observability, selfhosting]
---

# From Chaos to order: My homelab evolution (r2d2)

Most homelab journeys begin with a bit of spare hardware and a healthy dose of technical curiosity. Mine dates back to 2016, involving a raspberry Pi model B+ that miraculously survived the fatal crash of a DIY drone. What started as a simples Pi-hole project eventually evolved into the backbone of the ecosystem i call **r2d2** today.
## Hardware evolution: Where I/O is a king 👑

A lot of people start with a Raspberry Pi but soon hit the same wall i did: I/O and processing limitations. Trying to run a media server stack (Plex + arr's) via USB 2.0 and an old ARM processor its impossible.

After the "red light of death" of my raspberry, i moved to an inherited PC (AMD 2-cores, 8GB RAM). It was my real-world lab of Docker and volumes, but 8GB of RAM quickly became a bottleneck for the 15+ containers running and counting.

The current setup: Today, i run the homelab using an i5 3 generation (4-cores) with 16GB of RAM DDR3 and the loyal 1TB HD inherited. For a studies lab and home services this is a "sweet spot":  cheap hardware, but with virtualization and RAM sufficient to run Postgres instances and clusters K8s (using kind) without burn the cpu.

## The incident: Why "Set and Forget" is a risk

In early 2025, i learned the hard way that automation without observability its a technical debt.

I was running a `watchtower` to update Docker images automatically. I configured it via `docker run` and forgot about it. The problem? it wasn't cleaning up old images. Combined with the media server metadata cache, the HDD reached 100% capacity. The Ubuntu server collapsed. To prevent another disk-fill apocalypse, I moved away from the default `docker run` and integrated Watchtower into my management compose with explicit cleanup flags:
```yaml
services:
  watchtower:
    image: containrrr/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_POLL_INTERVAL=86400 # Check once a day
```
This ensures that old images are pruned immediately after a new one is pulled, keeping the storage footprint lean.

I tried a "disaster recovery" using dump tools to generate Compose files, but the result was a monolithic, 1,000-line YAML—unmaintainable and brittle. Lesson learned: if you can't versioning your infra, you don't have an infrastructure; you have a house of cards.

## Information architecture: Infra as Code (internal)

After the collapse, i decided that the rebuild would be structured. I created a Github repository and organized my `docker-compose` by context (scopes). This makes backup, migration and troubleshooting much easier.

One architectural decision I made during the migration was strictly using **Bind Mounts** instead of Named Volumes for stateful services. This allows me to keep all configuration files and database data in a structured `/opt/homelab/config` directory, which is much easier to back up via `rsync` or `restic` than dealing with Docker's internal volume storage.
### 1. Networking and DX local (Traefik + Pi-Hole)

The biggest game-changer was moving away from `IP:port` to real domains.

- **Pi-Hole**: Acts as my internal DNS server.
- **Traefik**: As a Reverse Proxy, listen to the Docker socket and resolves the names. Today, instead of memorizing obscure port combinations, access `portainer.r2d2` or `pihole.r2d2`. It's a huge gain in Developer Experience (DX) at house.

The beauty of Traefik lies in its **Docker Provider**. By exposing the Docker socket (securely via a proxy in a future iteration), services register themselves via labels. No more manual Nginx upstream edits:
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.portainer.rule=Host(`portainer.r2d2`)"
  - "traefik.http.services.portainer.loadbalancer.server.port=9000"
```
Combined with a wildcard DNS record in Pi-hole pointing to the host IP, the workflow for spinning up a new service is now fully declarative.
### 2. Media server and content automation

The classic stack (Radarr, Sonarr, Bazarr, Prowlarr + Plex) handles my content consumption. Recently, i added **Overseerr**, which centralizes all requests into a modern interface. Everything is downloaded using **qBitorrent** and organized automatically. i Maintain a 1080p quality limit (some cases i'm using 4k, but only special cases) due to space constraints -- a conscious trade-off between qualidade and disk space.

### 3. Productivity and Private "Cloud"

- **Syncthing**: My alternative to Obsidian Sync. It Synchronizes my note vault in real time between my devices, without costs and without data leaving my network.
- **Paperless-ngx**: My digital archive. I use it for invoices and documents OCR, transforming my homelab into an intelligent file server.
- **Stirling PDF**: Essential for manipulating PDFs locally, eliminating the need to use Sketchy third-party tools. (~~ilovepdf~~)

---

## The Future: LLMs and Observabillity

With disk error behind me, now i'm running a **Prometheus + Grafana** stack to monitor resources. Additionally, i started exploring Open Web-UI. It enables the use of LLM API's (Pay-as-you-go) or even running local models through Ollama, guaranteeing total privacy for proprietary or sensitive data.

My homelab is not an attempt to leave cloud services, but rather an engineering playground. Its the place where i can make mistakes, break production and learn about resilience without burning the company budget. 