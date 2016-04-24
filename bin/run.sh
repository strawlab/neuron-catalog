#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker run -d \
    --name neuron-catalog \
    --link neuron-catalog-db:db \
    -p 3000:80 \
    strawlab/neuron-catalog
