FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/vsftpd /var/run/vsftpd/empty \
	&& touch /var/log/vsftpd/vsftpd.log \
	&& chmod 755 /var/run/vsftpd /var/run/vsftpd/empty

COPY config/vsftpd.conf /etc/vsftpd.base.conf
COPY tools/setup_ftp.sh /setup_ftp.sh
RUN chmod +x /setup_ftp.sh

EXPOSE 21

ENTRYPOINT ["/setup_ftp.sh"]
