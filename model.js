// data model
// Loaded on both the client and the server

//////////////////////////////////////////////////////
DriverLines = new Meteor.Collection("driver_lines");
/*
  name: String
  _id: <int>
  neuron_types: [id, ...]
  neuropils: [id, ...]
  comments: [{[auth_stuff], comment: markdown_string, timestamp: hmm}, ...]
*/

//////////////////////////////////////////////////////
NeuronTypes = new Meteor.Collection("neuron_types");
/*
  name: String
  _id: <int>
  synonyms: [String, ...]
  neuropils: [id, ...]
  best_driver_lines: [id, ...]
*/

//////////////////////////////////////////////////////
Neuropils = new Meteor.Collection("neuropils");
/*
  name: String
  _id: <int>
*/



if (Meteor.isServer) {
  Meteor.publish("driver_lines", function () {
    if (this.userId) {
      return DriverLines.find({});
    }
  });
  Meteor.publish("neuron_types", function () {
    if (this.userId) {
      return NeuronTypes.find({});
    }
  });
  Meteor.publish("neuropils", function () {
    if (this.userId) {
      return Neuropils.find({});
    }
  });

  var logged_in_allow = {
    insert: function (userId, doc) {
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
  Neuropils.allow(logged_in_allow);
}
