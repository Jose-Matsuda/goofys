#!/bin/bash

#set -o xtrace
set -o errexit
set -o nounset

: ${CLOUD:="s3"}

function cleanup {
    if [ "$PROXY_PID" != "" ]; then
        kill $PROXY_PID
    fi
}

T=
if [ $# == 1 ]; then
    T="-check.f $1"
fi

trap cleanup EXIT

if [ $CLOUD == "s3" ]; then
    rm -Rf /tmp/s3proxy
    mkdir -p /tmp/s3proxy

    export LOG_LEVEL=warn
    PROXY_BIN="java -jar s3proxy.jar --properties test/s3proxy.properties"
elif [ $CLOUD == "azblob" ]; then
    rm -Rf /tmp/azblob
    mkdir -p /tmp/azblob
    PROXY_BIN="azurite-blob -l /tmp/azblob --blobPort 8080 -s"
    #PROXY_BIN="azurite-blob -l /tmp/azblob --blobPort 8080 -d /dev/stdout"
fi

stdbuf -oL -eL $PROXY_BIN &
PROXY_PID=$!

export CLOUD
go test -timeout 20m -v $(go list ./... | grep -v /vendor/) -check.vv $T
exit $?
