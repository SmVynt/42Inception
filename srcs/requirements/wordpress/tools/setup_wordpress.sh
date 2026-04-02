#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${MARIA_PORT:=3306}"
: "${WORDPRESS_VERSION:=6.4.3}"
: "${REDIS_HOST:=redis}"
: "${REDIS_PORT:=6379}"

# Docker Compose mounts secrets under /run/secrets/<secret_name>
if [ -r /run/secrets/db_password ]; then
	export WORDPRESS_DB_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_password)"
fi
if [ -r /run/secrets/wp_password ]; then
	export WP_ADMIN_PASSWORD="$(tr -d '\r\n' < /run/secrets/wp_password)"
fi
if [ -r /run/secrets/wp_author_password ]; then
	export WP_AUTHOR_PASSWORD="$(tr -d '\r\n' < /run/secrets/wp_author_password)"
fi
if [ -r /run/secrets/redis_password ]; then
	export REDIS_PASSWORD="$(tr -d '\r\n' < /run/secrets/redis_password)"
fi

var_exists() {
	eval val="\${$1:-}"
	if [ -z "$val" ]; then
		echo "${CLR_R}Error: $1 is not set. $2${CLR_RESET}" >&2
		exit 1
	fi
}

var_exists WORDPRESS_DB_PASSWORD "Mount secret db_password."
var_exists WP_ADMIN_PASSWORD     "Mount secret wp_password."
var_exists WP_AUTHOR_PASSWORD    "Mount secret wp_author_password."
var_exists WORDPRESS_DB_HOST     "Set in compose environment."
var_exists WORDPRESS_DB_NAME     "Set in .env or compose environment."
var_exists WORDPRESS_DB_USER     "Set in .env or compose environment."
var_exists DOMAIN_NAME           "Set in .env or Makefile exports."
var_exists WP_ADMIN_USER         "Set in .env (must NOT contain admin)."
var_exists WP_ADMIN_EMAIL        "Set in .env."
var_exists WORDPRESS_TITLE       "Set in .env."
var_exists WP_USER               "Set in .env (second WP user)."
var_exists WP_USER_EMAIL         "Set in .env (second WP user email)."

# Wait until MariaDB accepts connections (TCP + credentials)
while ! mysqladmin ping -h "${WORDPRESS_DB_HOST}" -P "${MARIA_PORT}" \
	-u "${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent 2>/dev/null; do
	echo "${CLR_Y}Waiting for MariaDB...${CLR_RESET}"
	sleep 1
done
echo "${CLR_G}MariaDB is reachable.${CLR_RESET}"

if ! wp core is-installed --allow-root 2>/dev/null; then
	echo "${CLR_Y}Installing WordPress (${WORDPRESS_VERSION})...${CLR_RESET}"
	wp core download --allow-root --locale=en_US --version="${WORDPRESS_VERSION}"

	wp config create --allow-root \
		--dbname="${WORDPRESS_DB_NAME}" \
		--dbuser="${WORDPRESS_DB_USER}" \
		--dbpass="${WORDPRESS_DB_PASSWORD}" \
		--dbhost="${WORDPRESS_DB_HOST}:${MARIA_PORT}" \
		--skip-check \
		--force

	wp core install --allow-root \
		--url="https://${DOMAIN_NAME}" \
		--title="${WORDPRESS_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}"

	# Subject: two users, one admin + one regular
	wp user create --allow-root \
		"${WP_USER}" "${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${WP_AUTHOR_PASSWORD}"

	chown -R www-data:www-data /var/www/html
	echo "${CLR_G}WordPress installed.${CLR_RESET}"
fi

#----------------------------------
#---------BONUS--------------------
#----------------------------------
# Redis-cache setup: can run both on fresh install and existing sites.
wp config set WP_CACHE true --raw --allow-root
wp config set WP_REDIS_CLIENT phpredis --allow-root
wp config set WP_REDIS_HOST "${REDIS_HOST}" --allow-root
wp config set WP_REDIS_PORT "${REDIS_PORT}" --raw --allow-root
wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root
wp config set WP_REDIS_READ_TIMEOUT 1 --raw --allow-root

if [ -n "${REDIS_PASSWORD:-}" ]; then
	wp config set WP_REDIS_PASSWORD "${REDIS_PASSWORD}" --allow-root
fi

if ! wp plugin is-installed redis-cache --allow-root >/dev/null 2>&1; then
	wp plugin install redis-cache --activate --allow-root
else
	wp plugin activate redis-cache --allow-root >/dev/null 2>&1 || true
fi

wp redis enable --allow-root >/dev/null 2>&1 || true
#---------BONUS--------------------

echo "${CLR_G}Starting PHP-FPM...${CLR_RESET}"
exec php-fpm8.2 -F
