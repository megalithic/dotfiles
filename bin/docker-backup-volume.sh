#!/bin/bash

VOLUME=${1:?'Volume name required as first argument'}

volume_switches="-v ${VOLUME}:/source/${VOLUME}"

set -x
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v $(pwd):/backup \
  ${volume_switches} \
  outstand/dockup:latest backup
