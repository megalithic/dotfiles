docker images | tail -n +2 | grep -v "none" | awk '{printf("%s:%s\n", $1, $2)}' | while read IMAGE; do
  echo $IMAGE
  filename="${IMAGE//\//-}"
  filename="${filename//:/-}.docker-image.tar.gz"
  docker save ${IMAGE} | pigz --stdout > $filename
done
