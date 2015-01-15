#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run -d \
    --link neuron-catalog-db:db \
    --name neuron-catalog-upload-processor \
    --env "METEOR_SETTINGS=$(cat ${THISDIR}/../server-config.json)" \
    strawlab/neuron-catalog-binary-upload-processor
