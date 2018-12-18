#!/usr/bin/env bash
pwd
cd baseimage
./build.sh
cd -
cd fuseimage
./build.sh
cd -
docker rmi -f gleb619/jboss-fuse-base