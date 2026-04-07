FROM debian:bookworm-slim

ARG PORTAINER_VERSION=2.21.4

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
	"https://github.com/portainer/portainer/releases/download/${PORTAINER_VERSION}/portainer-${PORTAINER_VERSION}-linux-amd64.tar.gz" \
	| tar -xz -C /

COPY tools/setup_portainer.sh /setup_portainer.sh
RUN chmod +x /setup_portainer.sh

EXPOSE ${PORTAINER_PORT:-9443}

ENTRYPOINT ["/setup_portainer.sh"]
