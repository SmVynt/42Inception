*This project has been created as part of the 42 curriculum by psmolin.*

## Description

**Inception** is a system administration project: a small web stack runs entirely in **Docker** on a **Linux virtual machine**. The goal is to learn how to containerize services, wire them with **Docker Compose**, persist data with **volumes**, isolate them with a **user-defined bridge network**, and expose the application **only over HTTPS (TLS 1.2/1.3) on port 443** via **NGINX**, while **WordPress (PHP-FPM)** and **MariaDB** are not directly exposed to the host.

This repository provides:

- A **Makefile** at the root to prepare host paths, secrets scaffolding, and drive `docker compose`.
- A **`srcs/`** tree with **`docker-compose.yml`**, **`.env`**, and one **Dockerfile per service** under `srcs/requirements/{nginx,wordpress,mariadb}/`.
- **`secrets/`** for sensitive files, mounted as **Docker secrets** where appropriate.
- For **secrets** and **.env** there are precreated **example** files.

## Instructions

### Prerequisites

- A **virtual machine** (Debian recommended) with **Docker** and **Docker Compose v2** (`docker compose`).
- Your 42 login used for paths and domain: data lives under **`/home/<login>/data/`**, site is **`https://<login>.42.fr`** (configure DNS or `/etc/hosts` on the client).

### Quick start

```bash
git clone <this repo url> inception
cd inception
./setup_vm.sh     # installs all required packages
make              # creates data dirs, copies .env / secrets from examples if missing
# Edit secrets/*.txt and srcs/.env (non-secret values only in .env)
make up           # build and start the stack
```

**The project will automatically use the user name as the login**

Open **`https://<login>.42.fr`** in a browser. The TLS certificate is **self-signed**; accept the security warning once.

Stop the Peoject:

```bash
make down
```

More targets: `make help`.

### What gets built

Images are **built locally** from Debian-based Dockerfiles. Compose builds and starts **nginx**, **wordpress**, and **mariadb** on a dedicated network.

Further **user-oriented** steps (admin URL, credentials) are in **`USER_DOC.md`**. **Developer** setup, data layout, and commands are in **`DEV_DOC.md`**.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose specification](https://docs.docker.com/compose/compose-file/)
- [NGINX SSL termination](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress](https://wordpress.org/documentation/)
- [MariaDB knowledge base](https://mariadb.com/kb/)

### Use of AI

AI assistants were used for:
- exploring Docker/Compose behavior
- debugging container startup and networking
- structuring documentation.

## Project description (design)

### Role of Docker in this project

Docker packages each service (NGINX, WordPress/PHP-FPM, MariaDB) with its dependencies into **images** built from **Dockerfiles**. **Docker Compose** declares how those containers **start**, which **volumes** and **secrets** they use, and how they **connect on a private network**. The VM provides an isolated, reproducible environment close to what evaluators use.

### Main design choices

- **One container per service**, one **Dockerfile** per image, aligned with Compose service names.
- **NGINX** terminates TLS and proxies PHP to **PHP-FPM** in the WordPress container; MariaDB is reachable only on the internal network.
- **Secrets** (passwords) live in **`secrets/*.txt`**, are **gitignored**, and are injected via **Compose `secrets:`** into **`/run/secrets/`** inside containers.
- **Non-secret** configuration is in **`srcs/.env`** (from **`.env.example`**), also not committed with real secrets.
- **Persistent data**: WordPress files and MariaDB data use **named volumes** whose backing store is under **`/home/<login>/data/`** on the host (see **`DEV_DOC.md`**).

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

Passwords for DB and WordPress users are kept out of Git and out of Dockerfiles; entrypoint scripts read secrets when present.

### Docker volumes vs bind mounts

| | Named volume | Bind mount |
|---|--------------|------------|
| Definition | `volumes:` entry in Compose, Docker manages storage location | Direct host path mounted into container (`./data:/var/lib/...`) |
| Portability | Name is stable across machines | Path must exist on host |

This project defines **named volumes** in Compose and pins their backing directories under **`/home/<login>/data/`** via the volume driver so data stays in the required host location.
