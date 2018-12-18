#!/usr/bin/env bash
DOCKER_IMAGE_NAME=gleb619/jboss-fuse-test
DOCKER_IMAGE_VERSION=latest

cd image
docker rmi --force=true ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
docker build --force-rm=true --rm=true -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} .
cd -

echo "============================
docker run --rm -tid -p 8181:8181 -h fuseadmin --name fuse gleb619/jboss-fuse-test
docker logs -f fuse
============================"