FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	redis-server \
	&& rm -rf /var/lib/apt/lists/*

COPY tools/setup_redis.sh /setup_redis.sh
RUN chmod +x /setup_redis.sh

EXPOSE 6379

ENTRYPOINT ["/setup_redis.sh"]