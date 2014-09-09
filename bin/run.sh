#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run -d \
    --name fly-neuron-catalog \
    -p 3000:80 \
    -v ${THISDIR}/../.docker-meteor-local:/fly-neuron-catalog/.meteor/local \
    strawlab/fly-neuron-catalog
