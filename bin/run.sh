#!/bin/bash

docker run -d \
    --name neuron-catalog \
    --link neuron-catalog-db:db \
    -p 3000:80 \
    strawlab/neuron-catalog
