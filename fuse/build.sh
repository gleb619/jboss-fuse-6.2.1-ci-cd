#!/usr/bin/env bash
pwd
cd baseimage
./build.sh
cd -
cd fuseimage
./build.sh
cd -