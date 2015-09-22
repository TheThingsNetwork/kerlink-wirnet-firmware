#!/bin/bash
docker build -t kerlink .
docker run -i --name kerlink kerlink sh /build.sh
docker cp kerlink:/root/buildroot/bin ../
docker rm kerlink
exit
