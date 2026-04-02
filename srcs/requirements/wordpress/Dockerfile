FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	php8.2-fpm \
	php8.2-cli \
	php8.2-mysql \
	php8.2-redis \
	mariadb-client \
	curl \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup_wordpress.sh /setup_wordpress.sh
RUN chmod +x /setup_wordpress.sh

EXPOSE ${WORDPRESS_PORT:-9000}

WORKDIR /var/www/html
ENTRYPOINT ["/setup_wordpress.sh"]
