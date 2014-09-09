#!/bin/bash
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t strawlab/fly-neuron-catalog ${THISDIR}/..
