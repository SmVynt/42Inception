FROM debian:bookworm-slim

# php8.2-cli: built-in server (PID 1). php8.2-mysql: mysqli + pdo_mysql for MariaDB/MySQL.
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	php8.2-cli \
	php8.2-mysql \
	&& rm -rf /var/lib/apt/lists/*

COPY tools/adminer-4.8.1-en.php /var/www/adminer/index.php
WORKDIR /var/www/adminer

COPY tools/setup_adminer.sh /setup_adminer.sh
RUN chmod +x /setup_adminer.sh

EXPOSE 8080

ENTRYPOINT ["/setup_adminer.sh"]
