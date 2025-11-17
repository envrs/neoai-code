#!/usr/bin/env bash
set -e
if ! type "docker" > /dev/null; then
    echo "Please install docker first!"
fi

docker build -t neoai-server:latest .
