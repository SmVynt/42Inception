#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

# Passwords: prefer Docker secrets
if [ -r /run/secrets/db_root_password ]; then
	MARIA_ROOT_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_root_password)"
fi
if [ -r /run/secrets/db_password ]; then
	MARIA_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_password)"
fi

var_exists() {
	# val becomes the value of the variable $1, or an empty string if the variable is not set
	eval val="\${$1:-}"
	# if val is empty, print error and exit
	[ -z "$val" ] && echo "${CLR_R}Error: $1 is not set. $2${CLR_RESET}" >&2 && exit 1
}

var_exists MARIA_DATABASE       "Set in .env."
var_exists MARIA_USER           "Set in .env."
var_exists MARIA_ROOT_PASSWORD  "Mount secret db_root_password."
var_exists MARIA_PASSWORD       "Mount secret db_password."

DATADIR=/var/lib/mysql
SOCKET=/run/mysqld/mysqld.sock

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# First setup only if $DATADIR/mysql does not exist
if [ ! -d "$DATADIR/mysql" ]; then
    # Initialize database
    echo "${CLR_Y}Initializing database...${CLR_RESET}"
	mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db >/dev/null

    # Launch MariaDB in bootstrap mode
    echo "${CLR_Y}Launching MariaDB...${CLR_RESET}"
	mariadbd --user=mysql --datadir="$DATADIR" \
		--skip-networking \
		--socket="$SOCKET" \
		--pid-file=/run/mysqld/mysqld-bootstrap.pid &
	bootstrap_pid=$!

    # Wait for MariaDB to bootstrap. We'll wait for 60 seconds, checking every second.
    echo "${CLR_Y}Waiting for MariaDB to bootstrap...${CLR_RESET}"
	i=0
	while ! mysqladmin --socket="$SOCKET" ping -u root --silent 2>/dev/null; do
		i=$((i + 1))
		if [ "$i" -gt 60 ]; then
			echo "MariaDB bootstrap did not start in time" >&2
			exit 1
		fi
		sleep 1
	done

    # Run a one-time SQL script to create database and user
	echo "Creating database and user..."
	mysql --socket="$SOCKET" -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MARIA_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIA_USER}'@'%' IDENTIFIED BY '${MARIA_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIA_DATABASE}\`.* TO '${MARIA_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIA_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Shut down initial MariaDB
    echo "${CLR_Y}Shutting down initial MariaDB...${CLR_RESET}"
	kill -TERM "$bootstrap_pid"
	wait "$bootstrap_pid" 2>/dev/null || true
fi

echo "${CLR_G}MariaDB is ready, starting...${CLR_RESET}"
exec mariadbd --user=mysql --datadir="$DATADIR"