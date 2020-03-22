# docker-stafwag-unbound

```Dockerfile``` to run unbound inside a docker container.
The unbound daemon will run as the unbound user. The uid/gid is mapped to
5000153.

## Installation

### clone the git repo

```
$ git clone https://github.com/stafwag/docker-stafwag-unbound.git
$ cd docker-stafwag-unbound
```

### Configuration

#### Port

The default DNS port is set to ```5353``` this port is mapped with the docker command to the default port 53 (see below).
If you want to use another port, you can edit ```etc/unbound/unbound.conf.d/interface.conf```.

#### Use unbound as an authoritative DNS server 

To use unbound as an authoritative authoritive DNS server - a DNS server that hosts DNS zones - add your zones file ```etc/unbound/zones/```.
Alternatively, you can also use a docker volume to mount ```/etc/unbound/zones/``` to your zone files.

The entrypoint script will create a zone.conf file to serve the zones.

You can use subdirectories. The zone file needs to have ```$ORIGIN``` set to our zone origin.

#### Use DNS-over-TLS

The default configuration uses [quad9](https://www.quad9.net/) to forward the DNS queries over TLS. 
If you want to use another vendor or you want to use the root DNS servers director you can remove this file.

### Build the image

```
$ docker build -t stafwag/unbound . 
```

## Run

### Recursive DNS server with DNS-over-TLS

Run

```
$ docker run -d --rm --name myunbound -p 127.0.0.1:53:5353 -p 127.0.0.1:53:5353/udp stafwag/unbound
```

Test

```
$ dig @127.0.0.1 www.wagemakers.be
```

### Authoritative dns server.

If you want to use unbound as an authoritative dns server you can use the steps below.

#### Create a directory with your zone files:

```
[staf@vicky ~]$ mkdir -p ~/docker/volumes/unbound/zones/stafnet
[staf@vicky ~]$ 
```

#### Create the zone files

##### Zone files

stafnet.zone:

```
$TTL	86400 ; 24 hours
$ORIGIN stafnet.local.
@  1D  IN	 SOA @	root (
			      20200322001 ; serial
			      3H ; refresh
			      15 ; retry
			      1w ; expire
			      3h ; minimum
			     )
@  1D  IN  NS @ 

stafmail IN A 10.10.10.10
```

stafnet-rev.zone:

```
$TTL    86400 ;
$ORIGIN 10.10.10.IN-ADDR.ARPA.
@       IN      SOA     stafnet.local. root.localhost.  (
                        20200322001; Serial
                        3h      ; Refresh
                        15      ; Retry
                        1w      ; Expire
                        3h )    ; Minimum
        IN      NS      localhost.
10      IN      PTR     stafmail.
```

Make sure that the volume directoy and zone files have the correct permissions.

```
$ chmod 755 ~/docker/volumes/unbound/zones/stafnet/
$ chmod 644 ~/docker/volumes/unbound/zones/stafnet/*
```

#### run the container

```
$ docker run -d --rm --name myunbound -v ~/docker/volumes/unbound/zones/stafnet:/etc//unbound/zones/ -p 127.0.0.1:53:5353 -p 127.0.0.1:53:5353/udp stafwag/unbound
```

#### test

```
[staf@vicky ~]$ dig @127.0.0.1 soa stafnet.local

; <<>> DiG 9.16.1 <<>> @127.0.0.1 soa stafnet.local
; (1 server found)
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 37184
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;stafnet.local.			IN	SOA

;; ANSWER SECTION:
stafnet.local.		86400	IN	SOA	stafnet.local. root.stafnet.local. 3020452817 10800 15 604800 10800

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Sun Mar 22 19:41:09 CET 2020
;; MSG SIZE  rcvd: 83

[staf@vicky ~]$ 
```

***Have fun***
