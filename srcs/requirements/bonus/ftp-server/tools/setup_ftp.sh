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
	PASV_RAW="$FTP_PASV_ADDRESS"
elif [ -n "${DOMAIN_NAME:-}" ]; then
	PASV_RAW="$DOMAIN_NAME"
else
	PASV_RAW=$(hostname -i 2>/dev/null | awk '{print $1}')
fi
# trim spaces / CR (common in .env)
PASV_RAW=$(printf '%s' "$PASV_RAW" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
if [ -z "$PASV_RAW" ]; then
	echo "ftp: set FTP_PASV_ADDRESS or DOMAIN_NAME for passive mode" >&2
	exit 1
fi

# vsftpd defaults to pasv_addr_resolve=NO → hostnames in pasv_address are invalid unless resolved.
PASV_ADDR="$PASV_RAW"
if ! printf '%s\n' "$PASV_ADDR" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
	RESOLVED=$(getent ahostsv4 "$PASV_RAW" 2>/dev/null | awk '{print $1; exit}')
	if [ -z "$RESOLVED" ]; then
		RESOLVED=$(getent hosts "$PASV_RAW" 2>/dev/null | awk '{print $1; exit}')
	fi
	if printf '%s\n' "$RESOLVED" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
		PASV_ADDR="$RESOLVED"
	else
		echo "ftp: could not resolve '${PASV_RAW}' to IPv4 for pasv_address" >&2
		echo "ftp: set FTP_PASV_ADDRESS to a numeric IP (e.g. 127.0.0.1 with VirtualBox port forwarding)" >&2
		exit 1
	fi
fi

if ! id -u "$FTP_USER" >/dev/null 2>&1; then
	if ! useradd -M -d /var/www/html -s /usr/sbin/nologin -g "$WP_GROUP" -o -u "$WP_UID" "$FTP_USER" 2>/dev/null; then
		echo "ftp: useradd failed for $FTP_USER" >&2
		exit 1
	fi
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

echo "${CLR_G}FTP configured. Starting...${CLR_RESET}"
echo "${CLR_G}FTP_USER: ${FTP_USER}${CLR_RESET}"
echo "${CLR_G}FTP_PASSWORD: ${FTP_PASSWORD}${CLR_RESET}"
echo "${CLR_G}PASV address (for clients): ${PASV_ADDR}${CLR_RESET}"

exec /usr/sbin/vsftpd /tmp/vsftpd.conf
