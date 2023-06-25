#!/bin/bash

BUILD_DIR=`cd ${0%/*} && pwd -P`

mkdir $BUILD_DIR/dist 2> /dev/null

echo "installing build dependencies..."
npm install --omit=peer --install-strategy=shallow --no-package-lock

docker buildx create --name redmatic-builder --platform linux/amd64,linux/arm/v7,linux/arm64 --use

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-amd64 --platform linux/amd64 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 .
CONTAINER_ID=$(docker create -it redmatic-amd64)
docker cp $CONTAINER_ID:/app/dist .
docker image rm -f redmatic-amd64

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-armv7 --platform linux/arm/v7 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 .
CONTAINER_ID=$(docker create -it redmatic-armv7)
docker cp $CONTAINER_ID:/app/dist .
docker image rm -f redmatic-armv7

docker buildx build --file ./BinaryBuilder.Dockerfile --load --tag redmatic-arm64 --platform linux/arm64 --no-cache --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 .
CONTAINER_ID=$(docker create -it redmatic-arm64)
docker cp $CONTAINER_ID:/app/dist .
docker image rm -f redmatic-arm64

docker buildx rm redmatic-builder

./build_release_body.sh
./build_change_history.sh

cat RELEASE_BODY.md
