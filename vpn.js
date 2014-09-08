Router.configure({
  layoutTemplate: 'MyLayout'
});

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


remove_driver_line = function ( my_id ) {
  function rdl( doc ) {
    var setter = {};
    for (i in this.fields) {
      var field = this.fields[i];
      var index = doc[field].indexOf(this.my_id);
      if (index!=-1) {
	doc[field].splice(index, 1);
	setter[field] = doc[field];
      }
    }
    this.coll.update( doc._id, {$set: setter});
  };

  NeuronTypes.find( {driver_lines: my_id} ).forEach( rdl,
						     {my_id:my_id,
						      coll:NeuronTypes,
						      fields:["best_driver_lines"]} );
  DriverLines.remove(my_id);
}

remove_neuron_type = function ( my_id ) {
  function rnt( doc ) {
    var index = doc.neuron_types.indexOf(this.my_id);
    // No need to check for index==-1 because we know it does not (except race condition).
    doc.neuron_types.splice(index, 1);
    this.coll.update( doc._id, {$set: {neuron_types: doc.neuron_types}});
  };

  DriverLines.find( {neuron_types: my_id} ).forEach( rnt, {my_id:my_id,coll:DriverLines} );
  NeuronTypes.remove(my_id);
}

remove_neuropile = function ( my_id ) {
  function rn( doc ) {
    var index = doc.neuropiles.indexOf(this.my_id);
    // No need to check for index==-1 because we know it does not (except race condition).
    doc.neuropiles.splice(index, 1);
    this.coll.update( doc._id, {$set: {neuropiles: doc.neuropiles}});
  };

  DriverLines.find( {neuron_types: my_id} ).forEach( rn, {my_id:my_id,coll:DriverLines} );
  NeuronTypes.find( {neuron_types: my_id} ).forEach( rn, {my_id:my_id,coll:NeuronTypes} );
  Neuropiles.remove(my_id);
}

if (Meteor.isServer) {
  DriverLines.remove({});
  NeuronTypes.remove({});
  Neuropiles.remove({});

  var id1 = DriverLines.insert({name: "VT37804-Gal4",
			       });
  var id2 = NeuronTypes.insert({name: "DCN",
				synonyms: ["LC14"],
				best_driver_lines: [id1]
			       });
  var id3 = NeuronTypes.insert({name: "AOpTu to lateral triangle projection neuron",
				synonyms: [],
				best_driver_lines: []
			       });
  var id4 = Neuropiles.insert({name: "lobula"
			      });
  var id5 = Neuropiles.insert({name: "lateral triangle"
			      });
  var id6 = Neuropiles.insert({name: "medulla"
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
