FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/vsftpd /etc/vsftpd \
	&& touch /var/log/vsftpd/vsftpd.log \
	&& : > /etc/vsftpd/pasv.conf

COPY config/vsftpd.conf /etc/vsftpd.conf
COPY tools/setup_ftp.sh /setup_ftp.sh
RUN chmod +x /setup_ftp.sh

EXPOSE 21

ENTRYPOINT ["/setup_ftp.sh"]
