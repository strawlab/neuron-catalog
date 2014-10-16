#!/bin/bash

docker run --rm \
    --link neuron-catalog-db:db \
    strawlab/neuron-catalog-binary-upload-processor
