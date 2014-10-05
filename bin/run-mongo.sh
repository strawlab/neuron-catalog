#!/bin/bash

docker run -d \
    --name neuron-catalog-db \
    -v /var/lib/neuron-catalog-db:/data/db \
    dockerfile/mongodb \
    mongod
