#!/bin/sh

docker run -d --rm --name myunbound -it -p 127.0.0.1:53:5353 -p 127.0.0.1:53:5353/udp stafwag/unbound
