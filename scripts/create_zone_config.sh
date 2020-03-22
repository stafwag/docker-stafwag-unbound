#!/bin/bash

# creates zones.cfg

UnboundZoneCfg=/etc/unbound/unbound.conf.d/zones.conf

> $UnboundZoneCfg || {
  echo "ERROR: Sorry failed to create $$UnboundZoneCfg"
  exit 1
}

chown root:unbound $UnboundZoneCfg
chmod 640  $UnboundZoneCfg

while read zoneFile; do

  echo "Processing: $zoneFile"

  if ! originLine=$(grep "^\$ORIGIN" $zoneFile); then

    echo "ERROR: Didn't find \$ORIGIN in $zoneFile"
    exit 1

  fi

  numberOfOriginLines=$(echo $originLine | wc -l)

  if [ "$numberOfOriginLines" -gt 1 ]; then
    echo "ERROR: $zoneFile has too many \$ORIGIN lines"
    exit 1
  fi

  origin=$(echo "$originLine" | awk '{ print $2 }' | sed 's/\.$//')

  echo "origin=${origin}"

  echo "auth-zone:" >> $UnboundZoneCfg
  echo "  name: $origin" >> $UnboundZoneCfg
  echo "  zonefile: $zoneFile" >> $UnboundZoneCfg
  echo >> $UnboundZoneCfg

done < <(find /etc/unbound/zones/ -name "*.zone")
