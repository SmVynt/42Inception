#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${REDIS_PORT:=6379}"

REDIS_FILE="/etc/redis/redis.conf"

# Check if the redis.conf file exists
if [ ! -f "$REDIS_FILE" ]; then
	echo "${CLR_R}redis.conf not found at ${REDIS_FILE}${CLR_RESET}" >&2
	exit 1
fi

set_or_append() {
    to_find="$1"
    to_replace="$2"
    if grep -q "^$to_find " "$REDIS_FILE"; then
        sed -i "s/^$to_find .*/$to_replace/" "$REDIS_FILE"
    else
        echo "$to_replace" >> "$REDIS_FILE"
    fi
}

echo "${CLR_Y}Configuring Redis...${CLR_RESET}"

# Check if the redis password is set
if [ -r /run/secrets/redis_password ]; then
	REDIS_PASSWORD="$(tr -d '\r\n' < /run/secrets/redis_password)"
    set_or_append 'requirepass' "requirepass ${REDIS_PASSWORD}"
fi

# Listen on container interface for other services in the compose network
set_or_append 'bind' 'bind 0.0.0.0'

# Keep protected mode enabled and explicitly allow only known behavior
set_or_append 'protected-mode' 'protected-mode yes'

# Memory policy for cache-like usage
set_or_append 'maxmemory' 'maxmemory 256mb'
set_or_append 'maxmemory-policy' 'maxmemory-policy allkeys-lru'

echo "${CLR_G}Redis configured. Starting...${CLR_RESET}"
exec redis-server "$REDIS_FILE" --port "$REDIS_PORT"
