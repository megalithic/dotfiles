#!/bin/bash

if [ ! -f volumes ]; then
  echo 'Expected `volumes` file to exist'
  exit 1
fi

volume_switches=""

while read VOLUME; do
  echo $VOLUME
  volume_switches="${volume_switches} -v ${VOLUME}:/source/${VOLUME}"
done <<< "$(cat volumes)"

set -x
docker run -it --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /bin/docker:/bin/docker \
  -v $(pwd):/backup \
  ${volume_switches} \
  outstand/dockup:latest restore
