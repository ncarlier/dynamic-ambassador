#!/bin/bash

if [ -z "$ETCD_HOST" ]
then
  echo "Missing ETCD_HOST env var"
  exit -1
fi

set -eo pipefail

#confd will start haproxy, since conf will be different than existing (which is null)

echo "[dynamic-ambassador] starting..."
echo "[dynamic-ambassador] using ETCD: $ETCD_HOST"

function config_fail()
{
	echo "Failed to start due to config error"
	exit -1
}

# Loop until confd has updated the haproxy config
n=0
until confd -onetime -node "$ETCD_HOST"; do
  if [ "$n" -eq "4" ];  then config_fail; fi
  echo "[dynamic-ambassador] waiting for confd to refresh haproxy.cfg"
  n=$((n+1))
  sleep $n
done

echo "[dynamic-ambassador] initial HAProxy config created: starting confd"

confd -node "$ETCD_HOST"
