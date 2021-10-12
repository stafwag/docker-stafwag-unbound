ARG BASE_IMAGE=debian:bullseye
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

# get unbound key
RUN unbound-anchor -v -4 || unbound-anchor -v -4
RUN chown root:unbound /etc/unbound/*.key
RUN chmod 0650  /etc/unbound/*.key
RUN chown root:unbound /etc/unbound/*.pem
RUN chmod 0650  /etc/unbound/*.pem

# config
COPY etc/unbound/unbound.conf.d/* /etc/unbound/unbound.conf.d/
RUN chown root:unbound /etc/unbound/unbound.conf.d/*
RUN chmod 640 /etc/unbound/unbound.conf.d/*

RUN chown root:unbound /etc/unbound/unbound.conf
RUN chmod 640 /etc/unbound/unbound.conf

# copy the required scripts
RUN mkdir -p /home/unbound/scripts
RUN chown -R root:unbound /home/unbound/

COPY scripts/* /home/unbound/scripts/
RUN chown root:unbound  /home/unbound/scripts/*
RUN chmod 550 /home/unbound/scripts/*

# setup local lan server
RUN mkdir /etc/unbound/zones/
RUN chown root:unbound /etc/unbound/zones/
COPY etc/unbound/zones/* /etc/unbound/zones/
RUN chown root:unbound /etc/unbound/zones/*
RUN chmod 640 /etc/unbound/zones/*

RUN touch /etc/unbound/unbound.conf.d/zones.conf
RUN /home/unbound/scripts/create_zone_config.sh
RUN chown root:unbound /etc/unbound/unbound.conf.d/zones.conf
RUN chmod 640 /etc/unbound/unbound.conf.d/zones.conf

EXPOSE 5353/tcp
EXPOSE 5353/udp
EXPOSE 8953/tcp
EXPOSE 8953/udp

USER unbound
WORKDIR /home/unbound

ENTRYPOINT ["/home/unbound/scripts/entrypoint.sh"]
