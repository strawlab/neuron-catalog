## Installation

By far the easiest way to try and run neuron-catalog is the demo server at
[oasis.sandstorm.io](https://oasis.sandstorm.io/apps/u1pa4174jqhvn93fkgr6u07mfgpk53dtgvfqqz9hec0pxk6c8nuh).

## Downloads

Releases can be downloaded
[here](https://github.com/strawlab/neuron-catalog/releases).

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

## Install for longer term runs

The neuron catalog software consists of a standard
[Meteor.js](https://www.meteor.com/) server. Instructions for getting
started with Meteor are
[here](http://docs.meteor.com/#/basic/quickstart). In a nutshell, once you have
Meteor installed, type this:

```
meteor run
```
