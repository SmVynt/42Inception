FROM debian:bookworm-slim

# Install nginx for web server
# Install gettext-base for text processing (we'll use it to process the nginx configuration file)
# Install openssl for SSL support (we'll use it to generate SSL certificates)
# --no-install-recommends: Don't install recommended packages.
# Remove apt lists to reduce image size.
RUN apt-get update && apt-get install -y --no-install-recommends \
	nginx \
	gettext-base \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

COPY ./conf/default_with_env.conf /etc/nginx/sites-available/default_with_env

COPY ./tools/setup_nginx.sh /setup_nginx.sh

RUN chmod +x /setup_nginx.sh

EXPOSE ${NGINX_PORT:-443}

ENTRYPOINT ["/setup_nginx.sh"]