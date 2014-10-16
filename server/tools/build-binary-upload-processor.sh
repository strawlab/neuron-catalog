#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build \
    -t strawlab/neuron-catalog-binary-upload-processor \
    ${THISDIR}/.
