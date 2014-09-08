// data model
// Loaded on both the client and the server

//////////////////////////////////////////////////////
DriverLines = new Meteor.Collection("driver_lines");
/*
  name: String
  _id: <int>
  neuron_types: [id, ...]
  neuropiles: [id, ...]
*/

//////////////////////////////////////////////////////
NeuronTypes = new Meteor.Collection("neuron_types");
/*
  name: String
  _id: <int>
  synonyms: [String, ...]
  neuropiles: [id, ...]
  best_driver_lines: [id, ...]
*/

//////////////////////////////////////////////////////
Neuropiles = new Meteor.Collection("neuropiles");
/*
  name: String
  _id: <int>
*/
