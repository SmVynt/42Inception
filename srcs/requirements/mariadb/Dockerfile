FROM debian:bookworm-slim

# Install mariadb for database server
# --no-install-recommends: Don't install recommended packages.
# Remove apt lists to reduce image size.
RUN apt-get update && apt-get install -y --no-install-recommends \
	mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

COPY ./conf/maria.conf /etc/mysql/mariadb.conf.d/
COPY ./tools/setup_maria.sh /setup_maria.sh

RUN chmod +x /setup_maria.sh

EXPOSE ${MARIA_PORT:-3306}

ENTRYPOINT ["/setup_maria.sh"]
