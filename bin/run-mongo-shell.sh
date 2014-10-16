#!/bin/bash

docker run -i -t --rm \
    --name neuron-catalog-mongo-shell \
    --link neuron-catalog-db:db \
    dockerfile/mongodb \
    mongo --host db
