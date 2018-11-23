DOCKER_IMAGE_NAME=gleb619/jboss-fuse-6.2.1
DOCKER_IMAGE_VERSION=latest

docker rmi --force=true ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}
docker build --force-rm=true --rm=true -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION} .

echo =========================================================================
echo Docker image is ready.  Try it out by running:
echo     docker run -p 8181:8181 -d --name fuse ${DOCKER_IMAGE_NAME}
echo     docker exec -ti fuse /bin/bash
echo =========================================================================
