FROM debian:bookworm-slim

# Install php-fpm for PHP FastCGI Process Manager (we'll use it to run PHP code)
# Install php-mysql for MySQL extension for PHP (we'll use it to connect to the MySQL database)
# Install ca-certificates for SSL support (we'll use it to verify the SSL certificates)
# --no-install-recommends: Don't install recommended packages.
RUN apt-get update && apt-get install -y --no-install-recommends \
	php-fpm \
	php-mysql \
	ca-certificates

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

CMD ["php-fpm8.2", "-F"]
