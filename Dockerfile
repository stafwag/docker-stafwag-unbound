ARG BASE_IMAGE=debian:buster
FROM $BASE_IMAGE
LABEL maintainer "staf wagemakers <staf@wagemakers.be>"

RUN groupadd unbound -g 5000153
RUN useradd unbound -u 5000153 -d /var/lib/unbound -s /usr/sbin/nologin -g unbound

RUN apt-get update  -y
RUN apt-get upgrade -y
RUN apt-get install unbound -y
RUN apt-get install unbound-anchor -y
RUN apt-get install unbound-host -y
RUN apt-get install dns-root-data -y

# config
COPY etc/unbound/unbound.conf.d/* /etc/unbound/unbound.conf.d/
RUN chown root:unbound /etc/unbound/unbound.conf.d/*
RUN chmod 640 /etc/unbound/unbound.conf.d/*
# get unbound key

RUN unbound-anchor -v || unbound-anchor -v

# setup local lan server

RUN mkdir /etc/unbound/zones/
RUN chown root:unbound /etc/unbound/zones/

COPY etc/unbound/zones/* /etc/unbound/zones/
RUN chown root:unbound /etc/unbound/zones/*
RUN chmod 640 /etc/unbound/zones/*

RUN mkdir /root/scripts
COPY scripts/* /root/scripts/
RUN chown root:root  /root/scripts/*
RUN chmod 500 /root/scripts/*

EXPOSE 5353/tcp
EXPOSE 5353/udp
EXPOSE 8953/tcp
EXPOSE 8953/udp

ENTRYPOINT ["/root/scripts/entrypoint.sh"]
