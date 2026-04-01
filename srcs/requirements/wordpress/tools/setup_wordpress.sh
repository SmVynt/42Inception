#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${MARIA_PORT:=3306}"
: "${WORDPRESS_VERSION:=6.4.3}"

# Docker Compose mounts secrets under /run/secrets/<secret_name>
if [ -r /run/secrets/db_password ]; then
	export WORDPRESS_DB_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_password)"
fi
if [ -r /run/secrets/wp_password ]; then
	export WP_ADMIN_PASSWORD="$(tr -d '\r\n' < /run/secrets/wp_password)"
fi

: "${WORDPRESS_DB_PASSWORD:?WORDPRESS_DB_PASSWORD missing (secret db_password)}"
: "${WP_ADMIN_PASSWORD:?WP_ADMIN_PASSWORD missing (secret wp_password)}"
: "${WORDPRESS_DB_NAME:?}"
: "${WORDPRESS_DB_USER:?}"
: "${DOMAIN_NAME:?}"
: "${WP_ADMIN_USER:?}"
: "${WP_ADMIN_EMAIL:?}"
: "${WORDPRESS_TITLE:?}"

# Wait until MariaDB accepts connections (TCP + credentials)
while ! mysqladmin ping -h mariadb -P "${MARIA_PORT}" \
	-u "${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent 2>/dev/null; do
	echo "${CLR_Y}Waiting for MariaDB...${CLR_RESET}"
	sleep 1
done
echo "${CLR_G}MariaDB is reachable.${CLR_RESET}"

if ! wp core is-installed 2>/dev/null; then
	echo "${CLR_Y}Installing WordPress (${WORDPRESS_VERSION})...${CLR_RESET}"
	wp core download --locale=en_US --version="${WORDPRESS_VERSION}"

	wp config create \
		--dbname="${WORDPRESS_DB_NAME}" \
		--dbuser="${WORDPRESS_DB_USER}" \
		--dbpass="${WORDPRESS_DB_PASSWORD}" \
		--dbhost="mariadb" \
		--dbport="${MARIA_PORT}" \
		--skip-check \
		--force

	wp core install \
		--url="https://${DOMAIN_NAME}" \
		--title="${WORDPRESS_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}"
	echo "${CLR_G}WordPress installed.${CLR_RESET}"
fi

echo "${CLR_G}Starting PHP-FPM...${CLR_RESET}"
exec php-fpm8.2 -F
