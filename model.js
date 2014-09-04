// data model
// Loaded on both the client and the server

//////////////////////////////////////////////////////
DriverLines = new Meteor.Collection("driver_lines");
/*
  name: String
  _id: <int>
  neuron_types: [id, ...]
  neuropils: [id, ...]
*/

//////////////////////////////////////////////////////
NeuronTypes = new Meteor.Collection("neuron_types");
/*
  name: String
  _id: <int>
  driver_lines: [id, ...]
  neuropils: [id, ...]
*/

//////////////////////////////////////////////////////
Neuropiles = new Meteor.Collection("neuropiles");
/*
  name: String
  _id: <int>
  driver_lines: [id, ...]
  neuron_types: [id, ...]
*/
