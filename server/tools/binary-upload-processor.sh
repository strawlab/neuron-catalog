#!/bin/bash

docker run -d \
    --link neuron-catalog-db:db \
    --name neuron-catalog-upload-processor \
    strawlab/neuron-catalog-binary-upload-processor
