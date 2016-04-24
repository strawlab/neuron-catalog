#!/bin/bash
set -euo pipefail

# Use correct version of node and npm for this version of Meteor.
# (See https://github.com/sandstorm-io/meteor-spk/issues/15#issuecomment-198103202 )
export BASEPATH=$(meteor node -e 'c=process.execPath.split("/"); console.log(c.slice(0, c.length-1).join("/"))')
sudo ln -sf $BASEPATH/node /usr/local/bin
sudo ln -sf $BASEPATH/npm /usr/local/bin

# Make meteor bundle

METEOR_WAREHOUSE_DIR="${METEOR_WAREHOUSE_DIR:-$HOME/.meteor}"
METEOR_DEV_BUNDLE=$(dirname $(readlink -f "$METEOR_WAREHOUSE_DIR/meteor"))/dev_bundle

cd /opt/app
meteor build --directory /home/vagrant/
(cd /home/vagrant/bundle/programs/server && "$METEOR_DEV_BUNDLE/bin/npm" install)

# Copy our launcher script into the bundle so the grain can start up.
mkdir -p /home/vagrant/bundle/opt/app/.sandstorm/
cp /opt/app/.sandstorm/launcher.sh /home/vagrant/bundle/opt/app/.sandstorm/
