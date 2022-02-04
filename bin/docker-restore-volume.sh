#!/bin/bash

if [ -z "$1" ]; then
  echo 'Volume name required'
  exit 1
fi

VOLUME="$1"

volume_switches="-v ${VOLUME}:/source/${VOLUME}"

set -x
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v $(pwd):/backup \
  ${volume_switches} \
  outstand/dockup:latest restore
