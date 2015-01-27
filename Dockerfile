# Dynamic ambassador
#
# VERSION 0.0.1

FROM debian:jessie

MAINTAINER Nicolas Carlier <https://github.com/ncarlier>

ENV DEBIAN_FRONTEND noninteractive

# Install haproxy.
RUN apt-get update && apt-get install -y supervisor rsyslog haproxy curl && apt-get clean
ADD default.cfg /etc/haproxy/haproxy.cfg
RUN echo "EXTRAOPTS=\"-f /etc/haproxy/confd.cfg\"" >> /etc/default/haproxy

# Install confd
ENV CONFD_URL https://github.com/kelseyhightower/confd/releases/download/v0.7.1/confd-0.7.1-linux-amd64
RUN (curl -L -o /usr/local/bin/confd $CONFD_URL && chmod +x /usr/local/bin/confd)
ADD confd /etc/confd
ADD entrypoint /usr/local/bin/entrypoint

# Install docker-gen
ENV DOCKERGEN_URL https://github.com/jwilder/docker-gen/releases/download/0.3.3/docker-gen-linux-amd64-0.3.3.tar.gz
RUN (cd /tmp && curl -L -o docker-gen.tgz $DOCKERGEN_URL && tar -C /usr/local/bin -xvzf docker-gen.tgz)
RUN mkdir /etc/docker-gen
ADD registration.sh.tmpl /etc/docker-gen/registration.sh.tmpl

# Setup supervisord
ADD supervisord.conf /etc/supervisor/conf.d/dynamic-ambassador.conf

# Setup etcd ip/port
ENV ETCD_HOST 172.17.42.1:4001

# Set docker host
ENV DOCKER_HOST unix:///tmp/docker.sock

# Expose ports
EXPOSE 80
EXPOSE 8080

ENTRYPOINT  ["/usr/local/bin/entrypoint"]

