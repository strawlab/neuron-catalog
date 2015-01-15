#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run -d \
    --name neuron-catalog \
    --link neuron-catalog-db:db \
    --env "METEOR_SETTINGS=$(cat ${THISDIR}/../server/server-config.json)" \
    -p 3000:80 \
    strawlab/neuron-catalog
