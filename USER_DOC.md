# User documentation — Inception stack

Simple guide for someone who needs to **run**, **access**, and **check** the services without changing the code.

## What this stack provides

### Core services

| Service | Role |
|---------|------|
| **NGINX** | HTTPS on **port 443** only (public entry). TLS 1.2/1.3. Serves static files from the WordPress volume and forwards PHP to WordPress. Routes bonus subdomains. |
| **WordPress + PHP-FPM** | WordPress application; PHP-FPM listens on **9000** inside the Docker network (not published on the host). |
| **MariaDB** | Database for WordPress; **3306** only inside the Docker network (not published on the host). |

### Bonus services

| Service | Role |
|---------|------|
| **Redis** | In-memory object cache for WordPress. Speeds up page loads by caching DB queries. **6379** inside the Docker network only. |
| **FTP Server** | vsftpd server providing file access to the WordPress volume. Published on **port 21** (control) + **21100** (passive data). |
| **Adminer** | Lightweight web UI for browsing and managing the MariaDB database. Accessible at `https://adminer.<login>.42.fr`. |
| **Web** | Personal portfolio site built with Next.js. Accessible at `https://web.<login>.42.fr`. |
| **Portainer** | Web UI for managing Docker containers, images, volumes, and networks. Accessible at `https://portainer.<login>.42.fr` or directly at `https://<VM_IP>:9443`. |

## VM setup (first time only)

### 1. Run the setup script

On a fresh VM, from the repository root, run as your **normal user** (not root):

```bash
./setup_vm.sh
```

This installs `docker.io`, `git`, `make`, `curl`, enables SSH, opens the FTP firewall ports, and prints next-step hints. After it finishes, **log out and back in** (or reboot) so the `docker` group applies to your session.

### 2. Configure port forwarding in your hypervisor

The VM does not have a public IP — your host machine needs to forward ports to it. In **VirtualBox** (or VMware equivalent):

`VM Settings → Network → Adapter 1 (NAT) → Port Forwarding`

| Name | Protocol | Host IP | Host Port | Guest IP | Guest Port | Purpose |
|------|----------|---------|-----------|----------|------------|---------|
| ssh | TCP | 127.0.0.1 | 3022 | | 22 | SSH access to VM |
| https | TCP | 127.0.0.1 | 443 | | 443 | All web services |
| ftp | TCP | 127.0.0.1 | 2121 | | 21 | FTP control |
| ftp-pasv | TCP | 127.0.0.1 | 21100 | | 21100 | FTP passive data |

> FTP rules are only needed if you plan to use the FTP service. SSH is optional but very convenient.

After adding the HTTPS rule, the client machine (your Windows/Linux/macOS host) can reach all web services at `127.0.0.1` — use that as `<VM_IP>` in the hosts file.

### 3. (Optional) SSH into the VM from your host

```bash
ssh -p 3022 <your_vm_username>@127.0.0.1
```

### 4. Set FTP passive address

Because the VM is behind NAT, vsftpd needs to know the address it should advertise to FTP clients. Set `FTP_PASV_ADDRESS` in `srcs/.env` to `127.0.0.1` (since you're forwarding through localhost):

```
FTP_PASV_ADDRESS=127.0.0.1
```

---

## Start and stop the project

On the VM, from the **repository root**:

First-time preparation:

```bash
make         # ensures data directories and .env / secrets files exist from examples
```

❗❗❗ Then **edit** the secret files and `.env` before relying on the site in production (see below).❗❗❗

Standard launch:

```bash
make up      # start (build images if needed, then run detached)
make down    # stop containers (data on volumes is kept)
```

## DNS / hosts setup

All services are reached through the same VM IP on **port 443**. NGINX routes traffic based on the subdomain.

First, find the VM IP from the VM terminal:
```bash
hostname -I | awk '{print $1}'
```

Then add these entries to your **client machine's** hosts file (not the VM), replacing `<VM_IP>` and `<login>`:

```
<VM_IP>  <login>.42.fr www.<login>.42.fr
<VM_IP>  adminer.<login>.42.fr
<VM_IP>  web.<login>.42.fr
<VM_IP>  portainer.<login>.42.fr
```

### You can do it like that on Linux

```bash
VM_IP=<VM_IP>
LOGIN=<login>
sudo tee -a /etc/hosts <<EOF
$VM_IP  $LOGIN.42.fr www.$LOGIN.42.fr
$VM_IP  adminer.$LOGIN.42.fr
$VM_IP  web.$LOGIN.42.fr
$VM_IP  portainer.$LOGIN.42.fr
EOF
```

**Browser warning:** The certificate is **self-signed**. Accept the warning once per subdomain.

## Access the services

### WordPress

- **Site:** `https://<login>.42.fr`
- **Admin panel:** `https://<login>.42.fr/wp-admin`

Log in with the **administrator** account defined in **`srcs/.env`** (`WP_ADMIN_USER`) and the password from **`secrets/wp_password.txt`**.

The subject requires a **second user** (non-administrator). This project creates an **author** user using **`WP_USER`** / **`WP_USER_EMAIL`** in `.env` and the password in **`secrets/wp_author_password.txt`**.

**Important:** The administrator username must **not** contain `admin`, `Admin`, `administrator`, or `Administrator`.

### Adminer

- **URL:** `https://adminer.<login>.42.fr`
- **System:** MySQL
- **Server:** `mariadb`
- **Username:** value of `MARIA_USER` in `srcs/.env` (default: `wp_user`)
- **Password:** content of `secrets/db_password.txt`
- **Database:** value of `MARIA_DATABASE` in `srcs/.env` (default: `wordpress`)

### Web (portfolio)

- **URL:** `https://web.<login>.42.fr`

No login required. This is a static Next.js portfolio site.

### Portainer

- **URL via nginx:** `https://portainer.<login>.42.fr`
- **URL direct:** `https://<VM_IP>:9443`

On first visit, Portainer will prompt you to **create an admin account** (username + password of your choice). Do this promptly — Portainer times out the initial setup after a few minutes; if it does, restart the container:

```bash
docker restart portainer
```

After login, select **"Get Started"** to manage the local Docker environment.

### FTP Server

- **Host:** `<VM_IP>`
- **Port:** `21`
- **Username:** value of `FTP_USER` in `srcs/.env` (default: `wpftp`)
- **Password:** content of `secrets/ftp_password_bonus.txt`
- **Mode:** Passive (PASV). Set **`FTP_PASV_ADDRESS`** in `srcs/.env` to the VM IP.

The FTP root is `/var/www/html` — the WordPress files volume. Use any FTP client (e.g. FileZilla).

## Credentials — where they live and how to manage them

| What | Where | Notes |
|------|--------|--------|
| DB user password | `secrets/db_password.txt` | MariaDB app user + WordPress DB connection. |
| MariaDB root password | `secrets/db_root_password.txt` | MariaDB `root@localhost`. |
| WordPress admin password | `secrets/wp_password.txt` | Administrator login. |
| Second WP user password | `secrets/wp_author_password.txt` | Author user. |
| Redis password | `secrets/redis_password_bonus.txt` | Redis AUTH password. |
| FTP password | `secrets/ftp_password_bonus.txt` | vsftpd user password. |
| Non-secret settings | `srcs/.env` | DB name, usernames, emails, ports, etc. |

These files should **not** be committed to Git (see `.gitignore`). To recreate templates from examples:

```bash
make init-secrets
```

(Existing files are not overwritten.)

## Check that services are running

```bash
make ps              # all containers on the Docker host
make logs            # follow all container logs live
```

Check a specific service:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs redis
docker logs ftp-server
docker logs adminer
docker logs web
docker logs portainer
```

All containers should be **Up**. If any restart in a loop, read their logs first.

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
