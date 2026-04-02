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

if ! id -u "$FTP_USER" >/dev/null 2>&1; then
	useradd -M -d /var/www/html -s /usr/sbin/nologin -g "$WP_GROUP" -o -u "$WP_UID" "$FTP_USER"
fi
printf '%s:%s\n' "$FTP_USER" "$FTP_PASSWORD" | chpasswd

install -d -m 0755 -o "$WP_UID" -g "$WP_GROUP" /var/www/html 2>/dev/null || true

# Single merged config (vsftpd does not support include=)
{
	cat /etc/vsftpd.base.conf
	printf '\n# Runtime (do not edit; regenerated each start)\n'
	printf 'listen_port=%s\n' "$FTP_PORT"
	printf 'pasv_enable=YES\n'
	printf 'pasv_address=%s\n' "$PASV_ADDR"
	printf 'pasv_min_port=%s\n' "$PASV_MIN_PORT"
	printf 'pasv_max_port=%s\n' "$PASV_MAX_PORT"
} > /tmp/vsftpd.conf

exec /usr/sbin/vsftpd /tmp/vsftpd.conf
