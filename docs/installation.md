## Quick install for testing

The neuron catalog can be most easily installed for testing using
[Vagrant](https://www.vagrantup.com/).

1. Install [VirtualBox](https://www.virtualbox.org/)
2. Install [Vagrant](https://www.vagrantup.com/).
3. Download the neuron catalog source code from our [GitHub repository](https://github.com/strawlab/neuron-catalog).
4. Open a terminal window into the `neuron-catalog` directory (containing the `Vagrantfile`).
5. Type `vagrant up`.
6. Wait a few minutes until for the Vagrant machine to come up.
7. Open [http://localhost:3450/](http://localhost:3450/) with your browser to visit your newly installed neuron catalog server.
8. You can stop the server and remove it with `vagrant destroy`.

If you want to enable image uploads, [configure Amazon AWS for image
storage](s3-config.md) and edit the `Vagrantfile` to add the relevant
S3 information before running the above steps.

## Install for longer term runs

The neuron catalog software consists of a standard
[Meteor.js](https://www.meteor.com/) server. Instructions for getting
started with Meteor are
[here](http://docs.meteor.com/#/basic/quickstart). Rougly speaking,
[configure Amazon AWS for image storage](s3-config.md), [create a
Meteor settings file](settings.md) and then run Meteor:

```
cp server/server-config.json.example server/server-config.json
# Edit server/server-config.json in a text editor as appropriate.
meteor run --settings server/server-config.json
```
