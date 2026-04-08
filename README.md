*This project has been created as part of the 42 curriculum by psmolin.*

## Description

**Inception** is a system administration project: a multi-service web stack runs entirely in **Docker** on a **Linux virtual machine**. The goal is to learn how to containerize services, wire them with **Docker Compose**, persist data with **volumes**, isolate them with a **user-defined bridge network**, and expose the application **only over HTTPS (TLS 1.2/1.3) on port 443** via **NGINX**, while backend services are not directly exposed to the host.

This repository provides:

- A **Makefile** at the root to prepare host paths, secrets scaffolding, and drive `docker compose`.
- A **`srcs/`** tree with **`docker-compose.yml`**, **`.env`**, and one **Dockerfile per service** under `srcs/requirements/`.
- **`secrets/`** for sensitive files, mounted as **Docker secrets** where appropriate.
- For **secrets** and **.env** there are precreated **example** files.

## Services

### Core

| Service | Role | Access |
|---------|------|--------|
| **NGINX** | HTTPS reverse proxy, TLS termination | `https://<login>.42.fr` |
| **WordPress + PHP-FPM** | CMS application | `https://<login>.42.fr` |
| **MariaDB** | WordPress database | Internal only |

### Bonus

| Service | Role | Access |
|---------|------|--------|
| **Redis** | WordPress object cache | Internal only |
| **FTP Server** | File access to WordPress volume | `<VM_IP>:21` |
| **Adminer** | Database web UI | `https://adminer.<login>.42.fr` |
| **Web** | Personal portfolio (Next.js) | `https://web.<login>.42.fr` |
| **Portainer** | Docker management UI | `https://portainer.<login>.42.fr` |

## Instructions

### Prerequisites

- A **virtual machine with GUI** (Debian recommended).
- `setup_vm.sh` installs Docker and Compose (`docker compose` or `docker-compose`) automatically.
- Your 42 login is used for paths and domain: data lives under **`/home/<login>/data/`**, site is **`https://<login>.42.fr`**.

### Quick start

```bash
git clone <this repo url> inception
cd inception
./setup_vm.sh     # installs required packages and updates /etc/hosts in the VM
make              # creates data dirs, copies .env / secrets from examples if missing
# Edit secrets/*.txt and srcs/.env (non-secret values only in .env)
make up           # build and start the stack
```

**The project will automatically use the user name as the login**

Open **`https://<login>.42.fr`** in a browser. The TLS certificate is **self-signed**; accept the security warning once.

`setup_vm.sh` automatically adds the required hosts entries inside the VM for:
`<login>.42.fr`, `www.<login>.42.fr`, `adminer.<login>.42.fr`, `web.<login>.42.fr`, `portainer.<login>.42.fr`.

Stop the project:

```bash
make down
```

More targets: `make help`.

### What gets built

Images are **built locally** from Debian-based Dockerfiles — no pre-made service images from Docker Hub. Compose builds and starts all services on a dedicated bridge network.

Further **user-oriented** steps (admin URL, credentials, bonus service URLs) are in **`USER_DOC.md`**. **Developer** setup, data layout, and commands are in **`DEV_DOC.md`**.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose specification](https://docs.docker.com/compose/compose-file/)
- [NGINX SSL termination](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress](https://wordpress.org/documentation/)
- [MariaDB knowledge base](https://mariadb.com/kb/)
- [Portainer documentation](https://docs.portainer.io/)
- [Next.js documentation](https://nextjs.org/docs)

### Use of AI

AI assistants were used for:
- exploring Docker/Compose behavior
- debugging container startup and networking
- structuring documentation.

## Project description (design)

### Role of Docker in this project

Docker packages each service with its dependencies into **images** built from **Dockerfiles**. **Docker Compose** declares how those containers **start**, which **volumes** and **secrets** they use, and how they **connect on a private network**. The VM provides an isolated environment.

### Main design choices

- **One container per service**, one **Dockerfile** per image, aligned with Compose service names.
- **NGINX** terminates TLS and routes traffic: PHP to WordPress/PHP-FPM, and subdomain-based reverse proxying to Adminer, Web, and Portainer.
- **Secrets** (passwords) live in **`secrets/*.txt`**, are **gitignored**, and are injected via **Compose `secrets:`** into **`/run/secrets/`** inside containers.
- **Non-secret** configuration is in **`srcs/.env`** (from **`.env.example`**), also not committed with real secrets.
- **Persistent data**: WordPress files, MariaDB data, and Portainer data use **named volumes** whose backing store is under **`/home/<login>/data/`** on the host.

### Virtual machines vs Docker

| | Virtual machine | Docker container |
|---|-----------------|------------------|
| Isolation | Full guest OS per VM | Shares host kernel; isolated processes, filesystem layers, network namespace |
| Size / boot | Heavier, slower to start | Lighter, starts in seconds |
| Use case | Different OS, strong isolation | Package and ship one app or service reproducibly |

Inception uses a **VM** as the evaluation host, and **Docker** inside it to run the multi-service app.

### Secrets vs environment variables

| | Environment variables | Docker secrets |
|---|----------------------|----------------|
| Storage | Often in `.env`, process environment | Files under `/run/secrets/` |
| Risk | Easy to leak in logs, `docker inspect`, child processes | Not passed by default to env; read explicitly in entrypoints |

Passwords for DB, WordPress, Redis, and FTP are kept out of Git and out of Dockerfiles; entrypoint scripts read secrets when present.

### Docker volumes vs bind mounts

| | Named volume | Bind mount |
|---|--------------|------------|
| Definition | `volumes:` entry in Compose, Docker manages storage location | Direct host path mounted into container |
| Portability | Name is stable across machines | Path must exist on host |

This project defines **named volumes** in Compose and pins their backing directories under **`/home/<login>/data/`** via the volume driver so data stays in the required host location.
