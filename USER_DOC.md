# User documentation — Inception stack

Simple guide for someone who needs to **run**, **access**, and **check** the services without changing the code.

## What this stack provides

| Service | Role |
|---------|------|
| **NGINX** | HTTPS on **port 443** only (public entry). TLS 1.2/1.3. Serves static files from the WordPress volume and forwards PHP to WordPress. |
| **WordPress + PHP-FPM** | WordPress application; PHP-FPM listens on **9000** inside the Docker network (not published on the host). |
| **MariaDB** | Database for WordPress; **3306** only inside the Docker network (not published on the host). |

Together they provide a **WordPress site** at **`https://<VM_login>.42.fr`**.

## Start and stop the project

On the VM, from the **repository root**:

First-time preparation:

```bash
make         # ensures data directories and .env / secrets files exist from examples
```

Then **edit** the secret files and `.env` before relying on the site in production (see below).

Standard launch:

```bash
make up      # start (build images if needed, then run detached)
make down    # stop containers (data on volumes is kept)
```

## Access the website

1. **Domain**  
   The site is intended to be reached as **`https://<login>.42.fr`**, with `<login>` matching the Linux user on the VM (the Makefile derives this from `id -un`, except a placeholder is used if you run as `root`).

2. **DNS / hosts**  
   Point that hostname to the machine that reaches the VM (e.g. VM IP, or `127.0.0.1` with **port forwarding** from the host to the VM on **443**).

3. **Browser warning**  
   The certificate is **self-signed**. The browser will show a warning (e.g. “not private” / unknown issuer). **Continue** after verifying you are connecting to the correct host.

## WordPress administration

- **Site:** `https://<login>.42.fr`  
- **Admin:** `https://<login>.42.fr/wp-admin`  

Log in with the **administrator** account defined in **`srcs/.env`** (`WP_ADMIN_USER`, `WP_ADMIN_EMAIL`) and the password from **`secrets/wp_password.txt`**.

The subject requires a **second user** (non-administrator). This project creates an **author** user using **`WP_USER`** / **`WP_USER_EMAIL`** in `.env` and the password in **`secrets/wp_author_password.txt`**.

**Important:** The administrator username must **not** contain `admin`, `Admin`, `administrator`, or `Administrator`.

## Credentials — where they live and how to manage them

| What | Where | Notes |
|------|--------|--------|
| DB user password | `secrets/db_password.txt` | One line, no extra spaces; used for MariaDB app user and WordPress DB connection. |
| MariaDB root password | `secrets/db_root_password.txt` | MariaDB `root@localhost`. |
| WordPress admin password | `secrets/wp_password.txt` | Administrator login. |
| Second WP user password | `secrets/wp_author_password.txt` | Author user. |
| Non-secret settings | `srcs/.env` | DB name, user names, emails, title, WordPress version, etc. |

These files should **not** be committed to Git (see `.gitignore`). To recreate templates from examples:

```bash
make init-secrets
```

(Existing files are not overwritten.)

## Check that services are running

```bash
make ps              # all containers on the Docker host
docker ps            # same idea
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Or follow logs live:

```bash
make logs
```

All three containers should be **Up**. If **wordpress** or **mariadb** restart in a loop, read their logs first.

## Reset project data (destructive)

Removes Compose volumes for this project and host data directories under `/home/<login>/data/` (may need `sudo`):

```bash
make clean
```

To also remove secret files and `srcs/.env`:

```bash
make fclean
```

Confirm with `y` when prompted.
