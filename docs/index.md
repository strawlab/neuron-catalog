# neuron-catalog

A simple web database for keeping track of neurons

---

## Overview

neuron-catalog is a web-based database for small groups (e.g. a lab)
collaborating on neuronal circuit mapping. It provides a simple
platform to organize your notes about driver lines, neuron types,
brain regions and putative connectivity. Each group that wants to run
the neuron-catalog can run their own server, as the software is free
and open source (GNU Affero General Public License v3). Because it is
run as an isolated, standalone database, the neuron-catalog can be
used as a collaborative lab-notebook to record novel observations
during the process of discovery. Thus, neuron-catalog complements
large-scale efforts which require extensive curation by providing a
collaboration platform before the data are ready for integration into
a finished dataset.

- Home page: [strawlab.org/neuron-catalog](http://strawlab.org/neuron-catalog)
- Download: [Release page](https://github.com/strawlab/neuron-catalog/releases)
- Project page on github:
[github.com/strawlab/neuron-catalog](https://github.com/strawlab/neuron-catalog)
- Demonstration: [neuron-catalog demonstration](https://neuron-catalog.meteor.com)
- Documentation: [Read The Docs](https://neuron-catalog.readthedocs.org/en/latest)
- Online forum: [gitter.im/strawlab/neuron-catalog](https://gitter.im/strawlab/neuron-catalog)

</a></li>

---

#### Host anywhere

neuron-catalog is simple to install and run on your own
infrastructure.

#### Simple

The user interface is a standard webpage with an emphasis on simple,
intuitive editing. No training should be needed to get up and running.

#### All data available to download

You are not locked in. All your data can be downloaded as a .json file
anytime. This can be uploaded to another instance of the
neuron-catalog or it can be parsed with other tools.

#### Easy to extend

The neuron-catalog is written in Javascript using the powerful [Meteor
framework](https://www.meteor.com). It is implemented as a standard
Meteor application, and hence all the documentation and help from this
large community is directly relevant.

#### Species specific specializations available

Currently for Drosophila melanogaster are [several
enhancements](specializations.md) such as linking to other online
databases. The design is implemented in a way that would be possible
to add similar features for other species.
