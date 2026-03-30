FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	php-fpm \
	php-mysql \
	ca-certificates

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

CMD ["php-fpm8.2", "-F"]
