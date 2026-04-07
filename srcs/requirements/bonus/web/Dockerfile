FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
	&& curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
	&& apt-get install -y --no-install-recommends nodejs \
	&& rm -rf /var/lib/apt/lists/*

COPY tools/site /site
WORKDIR /site

RUN npm install

COPY tools/setup_web.sh /setup_web.sh
RUN chmod +x /setup_web.sh

EXPOSE ${WEB_PORT:-3000}

ENTRYPOINT ["/setup_web.sh"]