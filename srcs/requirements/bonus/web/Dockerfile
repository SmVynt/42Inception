FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_22.x -o setup22.sh
RUN chmod +x setup22.sh
RUN ./setup22.sh && rm setup22.sh

RUN apt-get install -y --no-install-recommends nodejs \
	&& rm -rf /var/lib/apt/lists/*

COPY tools/site /site
WORKDIR /site

RUN npm install

COPY tools/setup_web.sh /setup_web.sh
RUN chmod +x /setup_web.sh

EXPOSE ${WEB_PORT:-3000}

ENTRYPOINT ["/setup_web.sh"]