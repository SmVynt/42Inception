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
	eval val="\${$1:-}"
	if [ -z "$val" ]; then
		echo "${CLR_R}Error: $1 is not set. $2${CLR_RESET}" >&2
		exit 1
	fi
}

var_exists MARIA_DATABASE       "Set in .env."
var_exists MARIA_USER           "Set in .env."
var_exists MARIA_ROOT_PASSWORD  "Mount secret db_root_password."
var_exists MARIA_PASSWORD       "Mount secret db_password."

DATADIR=/var/lib/mysql
SOCKET=/run/mysqld/mysqld.sock
INIT_MARK="$DATADIR/.inception_init_done"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Idempotent DB + user setup (stdin for mysql)
apply_schema() {
	cat <<EOF
CREATE DATABASE IF NOT EXISTS \`${MARIA_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIA_USER}'@'%' IDENTIFIED BY '${MARIA_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIA_DATABASE}\`.* TO '${MARIA_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIA_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
}

wait_bootstrap_root() {
	i=0
	while true; do
		if mysqladmin --socket="$SOCKET" ping -u root --silent 2>/dev/null; then
			apply_schema | mysql --socket="$SOCKET" -u root
			return 0
		fi
		if mysqladmin --socket="$SOCKET" ping -u root -p"$MARIA_ROOT_PASSWORD" --silent 2>/dev/null; then
			apply_schema | mysql --socket="$SOCKET" -u root -p"$MARIA_ROOT_PASSWORD"
			return 0
		fi
		i=$((i + 1))
		if [ "$i" -gt 60 ]; then
			return 1
		fi
		sleep 1
	done
}

start_bootstrap_daemon() {
	mariadbd --user=mysql --datadir="$DATADIR" \
		--skip-networking \
		--socket="$SOCKET" \
		--pid-file=/run/mysqld/mysqld-bootstrap.pid &
	echo $!
}

# First setup only if $DATADIR/mysql does not exist
if [ ! -d "$DATADIR/mysql" ]; then
	echo "${CLR_Y}Initializing database...${CLR_RESET}"
	mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db >/dev/null

	echo "${CLR_Y}Launching MariaDB...${CLR_RESET}"
	bootstrap_pid=$(start_bootstrap_daemon)

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
	apply_schema | mysql --socket="$SOCKET" -u root

	echo "${CLR_Y}Shutting down initial MariaDB...${CLR_RESET}"
	kill -TERM "$bootstrap_pid"
	wait "$bootstrap_pid" 2>/dev/null || true
	touch "$INIT_MARK"

# Partial install: data exists but init marker missing (e.g. old buggy entrypoint)
elif [ ! -f "$INIT_MARK" ]; then
	echo "${CLR_Y}Recovering MariaDB setup (app user / schema)...${CLR_RESET}"
	bootstrap_pid=$(start_bootstrap_daemon)
	if ! wait_bootstrap_root; then
		echo "${CLR_R}MariaDB recovery bootstrap failed (try: make clean + wipe data/mariadb).${CLR_RESET}" >&2
		kill -TERM "$bootstrap_pid" 2>/dev/null || true
		exit 1
	fi
	kill -TERM "$bootstrap_pid"
	wait "$bootstrap_pid" 2>/dev/null || true
	touch "$INIT_MARK"
fi

echo "${CLR_G}MariaDB is ready, starting...${CLR_RESET}"
exec mariadbd --user=mysql --datadir="$DATADIR" --port=${MARIA_PORT:-3306} --bind-address=0.0.0.0