#!/bin/sh
version="$(cat ./VERSION)"
project_dir=$(basename $(dirname $(realpath ./VERSION)))

echo "image name: $project_dir"
echo "version: $version"

podman build \
  --tag acherry.io/$project_dir:$version \
  --tag acherry.io/$project_dir:latest \
  -f ./Containerfile

