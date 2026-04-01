#!/bin/sh
set -eu

# Docker Compose mounts secrets under /run/secrets/<secret_name>
if [ -r /run/secrets/db_password ]; then
	export WORDPRESS_DB_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_password)"
fi
if [ -r /run/secrets/wp_password ]; then
	export WP_ADMIN_PASSWORD="$(tr -d '\r\n' < /run/secrets/wp_password)"
fi

exec "$@"
