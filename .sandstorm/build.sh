#!/bin/bash
set -euo pipefail

METEOR_WAREHOUSE_DIR="${METEOR_WAREHOUSE_DIR:-$HOME/.meteor}"
METEOR_DEV_BUNDLE=$(dirname $(readlink -f "$METEOR_WAREHOUSE_DIR/meteor"))/dev_bundle

cd /opt/app

meteor npm install
meteor build --directory /home/vagrant/
(cd /home/vagrant/bundle/programs/server && meteor npm install)
