#!/bin/bash

BUILD_DIR=`cd ${0%/*} && pwd -P`

mkdir $BUILD_DIR/dist 2> /dev/null

echo "installing build dependencies..."
npm install --omit=peer --global-style --no-package-lock

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-builder --platform linux/amd64 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=16 .
CONTAINER_ID=$(docker create -it redmatic-builder)
docker cp $CONTAINER_ID:/app/dist .
docker image rm redmatic-builder

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-builder --platform linux/arm/v7 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=16 .
CONTAINER_ID=$(docker create -it redmatic-builder)
docker cp $CONTAINER_ID:/app/dist .
docker image rm redmatic-builder

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-builder --platform linux/arm64 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=16 .
CONTAINER_ID=$(docker create -it redmatic-builder)
docker cp $CONTAINER_ID:/app/dist .
docker image rm redmatic-builder

./build_release_body.sh
./build_change_history.sh

cat RELEASE_BODY.md
