# neuron_catalog

A web-based user interface for a neuron catalog database.

This software was developed by the [Straw Lab](http://strawlab.org/)
and is based on [Meteor](http://meteor.com/). The software development
was supported by [ERC](http://erc.europa.eu/) Starting Grant 281884
FlyVisualCircuits and by [IMP](http://www.imp.ac.at/) core
funding. Software development happens on GitHub in the
[strawlab/neuron-catalog](https://github.com/strawlab/neuron-catalog).
project.

## Installation

There are two ways to install neuron_catalog. There is a development
install meant for local development and there is a deployment install
meant for deployment. For initial testing, use the development install
instructions.

### Development installation

Run the following commands in your bash console

    # In one console, run the Meteor webserver and Mongo database
    meteor run

    # after the above is running, get the URL for the database
    export MONGO_URL=`meteor mongo --url`

    # copy the example server configuration
    cp server/server-config.json.example server/server-config.json

    # edit the server configuration
    <your favorite editor> server/server-config.json

    # load the server configuration
    cat server/server-config.json | python server/tools/src/admin-config.py set
