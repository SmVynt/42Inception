#!/bin/sh
set -eu

CLR_R="\033[31m"
CLR_G="\033[32m"
CLR_Y="\033[33m"
CLR_RESET="\033[0m"

: "${WEB_PORT:=3000}"

echo "${CLR_G}Web configured. Starting...${CLR_RESET}"
exec npm run dev -- --port "$WEB_PORT"
