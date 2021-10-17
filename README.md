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


#### ```scripts/create_zone_config.sh``` helper script

The ```create_zone_config.sh``` helper script, can we help you to the ```zones.conf``` configuration file.
It's executed during the container build and creates the zones.conf from the datafiles in ```etc/unbound/zones```.

If you want to use a docker volume or configmaps/persistent volumes on Kubernetes. You can use this script to
generate the ```zones.conf``` a zones data directory.

```create_zone_config.sh``` has following arguments:

* **-f** Default: /etc/unbound/unbound.conf.d/zones.conf
  The zones.conf file to create
* **-d** Default: /etc/unbound/zones/
  The zones data source files
* **-p** Default: the realpath of zone files 
* **-s** Skip chown/chmod

#### Use unbound as an authoritative DNS server 

To use unbound as an authoritative authoritive DNS server - a DNS server that hosts DNS zones - add your zones file ```etc/unbound/zones/```.

During the creation of the image ```scripts/create_zone_config.sh``` is executed to create the zones configuration file.

Alternatively, you can also use a docker volume to mount ```/etc/unbound/zones/``` to your zone files. And a volume mount for the ```zones.conf```
configuration file.

You can use subdirectories. The zone file needs to have ```$ORIGIN``` set to our zone origin.

#### Use DNS-over-TLS

The default configuration uses [quad9](https://www.quad9.net/) to forward the DNS queries over TLS. 
If you want to use another vendor or you want to use the root DNS servers director you can remove this file.

### Build the image

```
$ docker build -t stafwag/unbound . 
```

To use a different BASE_IMAGE, you can use the --build-arg BASE_IMAGE=your_base_image.

```
$ docker build --build-arg BASE_IMAGE=stafwag/debian:bullseye -t stafwag/unbound .
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

```
[staf@vicky stafnet]$ cd ~/docker/volumes/unbound/zones/stafnet
[staf@vicky ~]$ 
```

#### Create the zone files 

##### Zone files

stafnet.zone:

```
$TTL  86400 ; 24 hours
$ORIGIN stafnet.local.
@  1D  IN  SOA @  root (
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
$ sudo chown -R root:5000153 ~/docker/volumes/unbound/
$ chmod 750 ~/docker/volumes/unbound/zones/stafnet/
$ chmod 640 ~/docker/volumes/unbound/zones/stafnet/*
```

Create the zones.conf configuration file.

```
[staf@vicky stafnet]$ cd ~/github/stafwag/docker-stafwag-unbound/
[staf@vicky docker-stafwag-unbound]$ 
```

The script will execute a ```chown``` and ```chmod``` on the generated ```zones.conf``` file and is excute with sudo for this reason.

```
[staf@vicky docker-stafwag-unbound]$ sudo scripts/create_zone_config.sh -f ~/docker/volumes/unbound/zones.conf -d ~/docker/volumes/unbound/zones/stafnet -p /etc/unbound/zones
Processing: /home/staf/docker/volumes/unbound/zones/stafnet/stafnet.zone
origin=stafnet.local
Processing: /home/staf/docker/volumes/unbound/zones/stafnet/stafnet-rev.zone
origin=1.168.192.IN-ADDR.ARPA
[staf@vicky docker-stafwag-unbound]$ 
```

Verify the generated ```zones.conf```

```
[staf@vicky docker-stafwag-unbound]$ sudo cat ~/docker/volumes/unbound/zones.conf
auth-zone:
  name: stafnet.local
  zonefile: /etc/unbound/zones/stafnet.zone

auth-zone:
  name: 1.168.192.IN-ADDR.ARPA
  zonefile: /etc/unbound/zones/stafnet-rev.zone

[staf@vicky docker-stafwag-unbound]$ 
```

#### run the container

```
$ docker run --rm --name myunbound -v ~/docker/volumes/unbound/zones/stafnet:/etc//unbound/zones/ -v ~/docker/volumes/unbound/zones.conf:/etc/unbound/unbound.conf.d/zones.conf -p 127.0.0.1:53:5353 -p 127.0.0.1:53:5353/udp stafwag/unbound
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
;stafnet.local.     IN  SOA

;; ANSWER SECTION:
stafnet.local.    86400 IN  SOA stafnet.local. root.stafnet.local. 3020452817 10800 15 604800 10800

;; Query time: 0 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Sun Mar 22 19:41:09 CET 2020
;; MSG SIZE  rcvd: 83

[staf@vicky ~]$ 
```

***Have fun***
