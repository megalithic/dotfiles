ls *.tar.gz | while read IMAGE; do
  echo "unpigz --stdout $IMAGE | docker load"
  unpigz --stdout $IMAGE | docker load
done
