#!/bin/bash

BUILD_DIR=`cd ${0%/*} && pwd -P`

rm -rf $BUILD_DIR/dist/* 
mkdir $BUILD_DIR/dist 2> /dev/null

echo "installing build dependencies..."
npm install --omit=peer --install-strategy=shallow --no-package-lock

docker buildx create --name redmatic-builder --platform linux/amd64,linux/arm/v7,linux/arm64 --use

docker buildx build --file ./BinaryBuilder.Dockerfile --platform linux/amd64 --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 --output ./dist .
docker buildx build --file ./BinaryBuilder.Dockerfile --platform linux/arm/v7 --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 --output ./dist .
docker buildx build --file ./BinaryBuilder.Dockerfile --platform linux/arm64 --build-arg VARIANT=bullseye --build-arg NODE_VERSION=18 --output ./dist .

docker buildx rm redmatic-builder

./build_release_body.sh
./build_change_history.sh

cat RELEASE_BODY.md
