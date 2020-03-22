#!/bin/bash

/root/scripts/create_zone_config.sh || {
  echo "ERROR: failed to create zone configuration"
  exit 1
}

unbound -c /etc/unbound/unbound.conf -d
