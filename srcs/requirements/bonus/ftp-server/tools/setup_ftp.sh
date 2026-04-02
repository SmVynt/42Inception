#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

# Debian www-data — same UID/GID as PHP-FPM in the WordPress container
WP_UID=33
WP_GROUP=www-data

: "${FTP_PORT:=21}"
: "${FTP_USER:=wpftp}"
: "${PASV_MIN_PORT:=21100}"
: "${PASV_MAX_PORT:=21110}"

echo "${CLR_Y}Setting up FTP password...${CLR_RESET}"

if [ ! -r /run/secrets/ftp_password ]; then
	echo "ftp: missing secret /run/secrets/ftp_password" >&2
	exit 1
fi

FTP_PASSWORD="$(tr -d '\r\n' < /run/secrets/ftp_password)"
if [ -z "$FTP_PASSWORD" ]; then
	echo "ftp: empty ftp_password secret" >&2
	exit 1
fi

# Set FTP_PASV_ADDRESS in .env to your VM/host IP, or rely on DOMAIN_NAME if it resolves for clients.
if [ -n "${FTP_PASV_ADDRESS:-}" ]; then
	PASV_ADDR="$FTP_PASV_ADDRESS"
elif [ -n "${DOMAIN_NAME:-}" ]; then
	PASV_ADDR="$DOMAIN_NAME"
else
	PASV_ADDR=$(hostname -i 2>/dev/null | awk '{print $1}')
fi
if [ -z "$PASV_ADDR" ]; then
	echo "ftp: set FTP_PASV_ADDRESS or DOMAIN_NAME for passive mode" >&2
	exit 1
fi

# FTP-only user, same numeric id as www-data so uploads match WordPress file ownership
if ! id -u "$FTP_USER" >/dev/null 2>&1; then
	useradd -M -d /var/www/html -s /usr/sbin/nologin -g "$WP_GROUP" -o -u "$WP_UID" "$FTP_USER"
fi
printf '%s:%s\n' "$FTP_USER" "$FTP_PASSWORD" | chpasswd

install -d -m 0755 -o "$WP_UID" -g "$WP_GROUP" /var/www/html 2>/dev/null || true

cat > /etc/vsftpd/pasv.conf <<EOF
listen_port=${FTP_PORT}
pasv_enable=YES
pasv_address=${PASV_ADDR}
pasv_min_port=${PASV_MIN_PORT}
pasv_max_port=${PASV_MAX_PORT}
EOF

exec /usr/sbin/vsftpd /etc/vsftpd.conf
