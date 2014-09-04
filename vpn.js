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

  DriverLines.insert({name: "xyz"});

/*
  Meteor.startup(function () {
    // code to run on server at startup
  });
*/
}
