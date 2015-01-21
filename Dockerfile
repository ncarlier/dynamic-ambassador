# Dynamic ambassador
#
# VERSION 0.0.1

FROM debian:jessie

MAINTAINER Nicolas Carlier <https://github.com/ncarlier>

ENV DEBIAN_FRONTEND noninteractive

# Install haproxy.
RUN apt-get update && apt-get install -y supervisor rsyslog haproxy curl inotify-tools && apt-get clean
ADD minimal.cfg /etc/haproxy/haproxy.cfg

# Install confd
ENV CONFD_URL https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64
RUN (curl -L -o /usr/local/bin/confd $CONFD_URL && chmod +x /usr/local/bin/confd)
ADD confd /etc/confd

# Setup supervisord
ADD supervisord.conf /etc/supervisor/conf.d/dynamic-ambassador.conf

# Setup etcd ip/port
ENV ETCD_HOST 172.17.42.1:4001

# Expose ports
EXPOSE 80
EXPOSE 8080

ENTRYPOINT  ["/usr/bin/supervisord"]

CMD ["-n"]
