Router.map(function() {
  this.route('home', {path: '/'});

  this.route('driver_lines');
  this.route('driver_line_show', {
    path: '/driver_lines/:_id',
    data: function() { return DriverLines.findOne(this.params._id); }
  });

  this.route('neuron_types');
  this.route('neuron_type_show', {
    path: '/neuron_types/:_id',
    data: function() { return NeuronTypes.findOne(this.params._id); }
  });

  this.route('neuropiles');
  this.route('neuropile_show', {
    path: '/neuropiles/:_id',
    data: function() { return Neuropiles.findOne(this.params._id); }
  });

});

if (Meteor.isServer) {
  DriverLines.remove({});
  NeuronTypes.remove({});
  Neuropiles.remove({});

  var id1 = DriverLines.insert({name: "VT37804-Gal4",
			       });

  var id2 = NeuronTypes.insert({name: "DCN",
				driver_lines: [id1]
			       });
  var id3 = NeuronTypes.insert({name: "AOpTu to lateral triangle projection neuron",
				driver_lines: [id1]
			       });

  var id4 = Neuropiles.insert({name: "lobula",
			       driver_lines: [id1],
			       neuron_types: [id2]
			      });
  var id5 = Neuropiles.insert({name: "lateral triangle",
			       driver_lines: [id1],
			       neuron_types: [id3]
			      });
  var id6 = Neuropiles.insert({name: "medulla",
			       driver_lines: [id1],
			       neuron_types: [id2]
			      });

  // Pass 2 : update
  DriverLines.update(id1, {$set: {neuron_types: [id2,id3],
				  neuropiles: [id4,id5,id6]}});
  NeuronTypes.update(id2, {$set: {neuropiles: [id4,id6]}});
  NeuronTypes.update(id3, {$set: {neuropiles: [id5]}});

/*
  Meteor.startup(function () {
    // code to run on server at startup
  });
*/
}
