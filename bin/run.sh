#!/bin/bash

docker run -d \
    --name fly-neuron-catalog \
    -p 3000:80 \
    -v /fly-neuron-catalog/.meteor/local \
    strawlab/fly-neuron-catalog
