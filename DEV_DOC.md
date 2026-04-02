# Developer documentation — Inception

How to reproduce the environment, build, run, and debug the project.

## Prerequisites

- **OS:** Linux **virtual machine**.
- **Packages:** `docker.io`, **Docker Compose plugin** (`docker compose`), `git`, `make`, `sudo`.
- **Optional:** run **`./setup_vm.sh`** from the repo on a fresh VM to install Docker, OpenSSH, and print port-forward hints.
- **User:** Work as a normal user in the **docker** group (`sudo usermod -aG docker "$USER"` then **log out and back in**).
- **Disk:** Space for images plus persistent data under **`/home/<login>/data/`**.

## Repository layout

```
.
├── Makefile                 # drives compose; exports WP_VOLUME, DB_VOLUME, DOMAIN_NAME
├── secrets/                 # real secrets gitignored; *.example committed
├── README.md, USER_DOC.md, DEV_DOC.md
└── srcs/
    ├── docker-compose.yml   # services, networks, volumes, secrets
    ├── .env                 # from .env.example — local only, no passwords
    └── requirements/
        ├── nginx/           # Dockerfile, conf/, tools/setup_nginx.sh
        ├── wordpress/       # Dockerfile, conf/www.conf, tools/setup_wordpress.sh
        └── mariadb/         # Dockerfile, conf/, tools/setup_maria.sh
```

Subject constraint: everything needed to configure the project lives under **`srcs/`** (plus Makefile and secrets at root as in the subject example).

## Configuration files and secrets

### `srcs/.env`

Copy from **`srcs/.env.example`** (or run `make` / `make init-secrets`):

- `MARIA_DATABASE`, `MARIA_USER`, `MARIA_PORT`
- `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WORDPRESS_TITLE`
- `WP_USER`, `WP_USER_EMAIL`
- `WORDPRESS_VERSION`

**Do not** put passwords here. `DOMAIN_NAME` can be set here; the Makefile also exports **`DOMAIN_NAME=<login>.42.fr`** for Compose interpolation.

### `secrets/*.txt`

One file per secret, **single line** (scripts strip newlines). Examples are in **`secrets/*.example`**.

| File | Consumed by |
|------|-------------|
| `db_password.txt` | MariaDB (app user), WordPress (DB) |
| `db_root_password.txt` | MariaDB root |
| `wp_password.txt` | WordPress administrator |
| `wp_author_password.txt` | Second WP user (author) |

Compose mounts them as **secrets**; entrypoints read **`/run/secrets/<name>`**.

## Build and launch

From the **repository root**:

```bash
make              # mkdir -p ~/data/{wordpress,mariadb}, seed .env / secrets if missing
make up           # docker compose up -d --build (with exported env)
```

Environment exported by Make for Compose:

- **`WP_VOLUME`** — host path for WordPress files volume (default `/home/<user>/data/wordpress`)
- **`DB_VOLUME`** — host path for MariaDB data volume (default `/home/<user>/data/mariadb`)
- **`DOMAIN_NAME`** — TLS CN and WordPress URL host (default `<user>.42.fr`)

Override by exporting before `make` or editing the Makefile for local dev.

Other useful targets:

| Target | Action |
|--------|--------|
| `make build` | `docker compose build` |
| `make rebuild` | `build --no-cache` then `up -d` |
| `make down` | stop stack |
| `make logs` | `docker compose logs -f` |
| `make clean` | `compose down -v` + `sudo rm -rf` data dirs |
| `make fclean` | `clean` + remove `secrets/*.txt` and `srcs/.env` (prompt) |
| `make help` | short help |

## Managing containers and volumes

```bash
docker compose -f srcs/docker-compose.yml --project-directory srcs ps -a
docker compose -f srcs/docker-compose.yml --project-directory srcs logs -f <service>
docker compose -f srcs/docker-compose.yml --project-directory srcs exec wordpress sh
docker compose -f srcs/docker-compose.yml --project-directory srcs exec mariadb mysql -u root -p
```

Named volumes in Compose map to the host paths set by **`WP_VOLUME`** / **`DB_VOLUME`**. `make clean` runs **`down -v`** (removes those compose volumes) and deletes the host directories.

## Where data persists

| Data | Volume name in Compose | Host location (this project) |
|------|-------------------------|------------------------------|
| WordPress files | `wordpress_data` | `$WP_VOLUME` (default `~/data/wordpress`) |
| MariaDB files | `mariadb_data` | `$DB_VOLUME` (default `~/data/mariadb`) |

## Images and services

- **Image names** follow Compose **service** names (`nginx`, `wordpress`, `mariadb`) when built with this file.
- **Base image:** Debian bookworm-slim (penultimate stable Debian line at project time).
- **Entrypoints:** shell scripts in each `tools/` directory; main process is **`exec`**’d (e.g. `nginx`, `php-fpm`, `mariadbd`).
