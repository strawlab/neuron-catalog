// data model
// Loaded on both the client and the server

//////////////////////////////////////////////////////
DriverLines = new Meteor.Collection("driver_lines");
/*
  name: String
  _id: <int>
  neuron_types: [id, ...]
  neuropiles: [id, ...]
  comments: [{[auth_stuff], comment: markdown_string, timestamp: hmm}, ...]
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



if (Meteor.isServer) {
Meteor.publish("driver_lines", function () {
  return DriverLines.find({});
});
Meteor.publish("neuron_types", function () {
  return NeuronTypes.find({});
});
Meteor.publish("neuropiles", function () {
  return Neuropiles.find({});
});

var logged_in_allow = {insert: function (userId, doc) {
    return !!userId;
  },
  update: function (userId, doc, fields, modifier) {
    return !!userId;
  },
  remove: function (userId, doc) {
    return !!userId;
  },
};

DriverLines.allow(logged_in_allow);
NeuronTypes.allow(logged_in_allow);
Neuropiles.allow(logged_in_allow);
}
