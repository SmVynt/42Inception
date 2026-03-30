FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y nginx \
	gettext-base \
	openssl

COPY ./conf/default_with_env /etc/nginx/sites-available/default_with_env

COPY ./tools/setup_nginx.sh /setup_nginx.sh

RUN chmod +x /setup_nginx.sh

ENTRYPOINT ["/setup_nginx.sh"]