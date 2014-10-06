#!/bin/bash

docker run -i -t --rm \
    --link neuron-catalog-db:db \
    dockerfile/mongodb \
    mongo --host db
