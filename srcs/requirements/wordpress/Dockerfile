FROM debian:bookworm-slim

# Install php-fpm for PHP FastCGI Process Manager (we'll use it to run PHP code)
# Install php-mysql for MySQL extension for PHP (we'll use it to connect to the MySQL database)
# Install ca-certificates for SSL support (we'll use it to verify the SSL certificates)
# --no-install-recommends: Don't install recommended packages.
# Remove apt lists to reduce image size.
RUN apt-get update && apt-get install -y --no-install-recommends \
	php-fpm \
	php-mysql \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/setup_wordpress.sh /setup_wordpress.sh
RUN chmod +x /setup_wordpress.sh

WORKDIR /var/www/html
ENTRYPOINT ["/setup_wordpress.sh"]
CMD ["php-fpm8.2", "-F"]
