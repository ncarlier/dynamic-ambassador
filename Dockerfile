# Dynamic ambassador
#
# VERSION 0.0.1

FROM debian:jessie

MAINTAINER Nicolas Carlier <https://github.com/ncarlier>

ENV DEBIAN_FRONTEND noninteractive

# Install haproxy.
RUN apt-get update && apt-get install -y haproxy curl && apt-get clean
RUN sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy

# Install confd
ENV CONFD_URL https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64
RUN (curl -L -o /usr/local/bin/confd $CONFD_URL && chmod +x /usr/local/bin/confd)

# Install startup script
ADD entrypoint.sh /usr/local/bin/entrypoint

# Install confd files
ADD confd /etc/confd

# Setup etcd ip/port
ENV ETCD_NODE 171.17.42.1:4001

# Expose ports
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint"]

