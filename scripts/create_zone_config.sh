#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# creates zones.conf
usage() {
  echo >&2
  echo >&2 "Usage: $(basename $0)"
  echo >&2
  echo >&2 "       optional arguments:"
  echo >&2
  echo >&2 "       -f Default: /etc/unbound/unbound.conf.d/zones.conf"
  echo >&2 "          The zones.conf file to create"
  echo >&2 "       -d Default: /etc/unbound/zones/"
  echo >&2 "          The zones data source files"
  echo >&2 "       -p Default: the realpath of zone files "
  echo >&2 "       -s Skip chown/chmod"
  echo >&2
  exit 1
}

UnboundZoneCfg="/etc/unbound/unbound.conf.d/zones.conf"
ZoneDataDir="/etc/unbound/zones/"
ZonesPath=""
SkipPerms=""

while getopts “hsd:f:p:” OPTION; do
  case $OPTION in
    f)
      UnboundZoneCfg=$OPTARG
      ;;
    d)
      ZoneDataDir=$OPTARG
      ;;
    p)
      ZonesPath=$(echo $OPTARG | sed -e 's@/$@@')
      ;;
    s)
      SkipPerms=1
      ;;
    h)
      usage
      ;;
    ?)
      usage
      ;;
  esac
done

> $UnboundZoneCfg || {
  echo "ERROR: Sorry failed to create $$UnboundZoneCfg"
  exit 1
}

ZoneDataDirLen=$(echo $ZoneDataDir | wc -m)

while read zoneFile; do

  echo >&2 "Processing: $zoneFile"

  if ! originLine=$(grep "^\$ORIGIN" $zoneFile); then

    echo "ERROR: Didn't find \$ORIGIN in $zoneFile"
    exit 1

  fi

  numberOfOriginLines=$(echo $originLine | wc -l)

  if [ "$numberOfOriginLines" -gt 1 ]; then
    echo >&2 "ERROR: $zoneFile has too many \$ORIGIN lines"
    exit 1
  fi

  origin=$(echo "$originLine" | awk '{ print $2 }' | sed 's/\.$//')

  echo >&2 "origin=${origin}"

  if [ -n "$ZonesPath" ]; then
    zoneBaseFile=$(echo $zoneFile | cut -c${ZoneDataDirLen}- | sed -e 's@^/@@')
    zoneFile="${ZonesPath}/${zoneBaseFile}"
  fi

  echo "auth-zone:" >> $UnboundZoneCfg
  echo "  name: $origin" >> $UnboundZoneCfg
  echo "  zonefile: $zoneFile" >> $UnboundZoneCfg
  echo >> $UnboundZoneCfg

done < <(find "$ZoneDataDir" -name "*.zone")

if [ "$SkipPerms" != "1" ]; then
  chown root:5000153 $UnboundZoneCfg
  chmod 640 $UnboundZoneCfg
fi
