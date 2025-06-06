#!/usr/bin/env nix-shell
#! nix-shell -i bash -p podman

IMAGE_NAME="dockerstefn/patlog"
TAG="latest"

docker build -t "${IMAGE_NAME}:${TAG}" .
docker login
docker push "${IMAGE_NAME}:${TAG}"
