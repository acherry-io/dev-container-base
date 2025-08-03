#!/bin/sh
source .env
version="$(cat ../VERSION)"
project_dir=$(realpath $BASH_SOURCE | cut -d / -f5)

echo $version
echo $project_dir

podman build \
  --tag $HOST/$project_dir:$version \
  --tag $HOST/$project_dir:latest \
  -f ./Containerfile

