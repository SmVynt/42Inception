#!/bin/sh
set -eu

# Passwords: prefer Docker secrets
if [ -r /run/secrets/db_root_password ]; then
	MARIA_ROOT_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_root_password)"
fi
if [ -r /run/secrets/db_password ]; then
	MARIA_PASSWORD="$(tr -d '\r\n' < /run/secrets/db_password)"
fi

# Non-secret DB settings from .env / environment
: "${MARIA_DATABASE:?MARIA_DATABASE is required}"
: "${MARIA_USER:?MARIA_USER is required}"
: "${MARIA_ROOT_PASSWORD:?MARIA_ROOT_PASSWORD is required (set env or secrets/db_root_password.txt)}"
: "${MARIA_PASSWORD:?MARIA_PASSWORD is required (set env or secrets/db_password.txt)}"

DATADIR=/var/lib/mysql
SOCKET=/run/mysqld/mysqld.sock

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# First setup only if $DATADIR/mysql does not exist
if [ ! -d "$DATADIR/mysql" ]; then
    # Initialize database
    echo "Initializing database..."
	mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db >/dev/null

    # Launch MariaDB in bootstrap mode
    echo "Launching MariaDB..."
	mariadbd --user=mysql --datadir="$DATADIR" \
		--skip-networking \
		--socket="$SOCKET" \
		--pid-file=/run/mysqld/mysqld-bootstrap.pid &
	bootstrap_pid=$!

    # Wait for MariaDB to bootstrap. We'll wait for 60 seconds, checking every second.
    echo "Waiting for MariaDB to bootstrap..."
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
    echo "Shutting down initial MariaDB..."
	kill -TERM "$bootstrap_pid"
	wait "$bootstrap_pid" 2>/dev/null || true
fi

exec mariadbd --user=mysql --datadir="$DATADIR"