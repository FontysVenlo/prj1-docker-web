#!/usr/bin/env bash
docker rm -f prj1_web:dev
docker build --tag=prj1_web:dev .
docker run -p 80:80 --rm --name prj1_web prj1_web:dev