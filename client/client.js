function get_driver_lines( my_obj ) {
  var result = [];
  if ('driver_lines' in my_obj) {
    result = my_obj.driver_lines.map( function (_id) { return DriverLines.findOne(_id) } );
   }
  return result;
}

function get_neuron_types( my_obj ) {
  var result = [];
  if ('neuron_types' in my_obj) {
    result = my_obj.neuron_types.map( function (_id) { return NeuronTypes.findOne(_id) } );
   }
  return result;
}

function get_neuropiles( my_obj ) {
  var result = [];
  if ('neuropiles' in my_obj) {
    result = my_obj.neuropiles.map( function (_id) { return Neuropiles.findOne(_id) } );
   }
  return result;
}

// -------------

Template.driver_lines.driver_line_cursor = function () {
  return DriverLines.find({});
}

Template.driver_line_show.neuron_types = function () {
  return get_neuron_types(this);
}

Template.driver_line_show.neuropiles = function () {
  return get_neuropiles(this);
}

Template.driver_line_show.events({
  'click a.delete': function(e) {
    e.preventDefault();
    remove_driver_line( this._id );
  }
});

// -------------

Template.neuron_types.neuron_type_cursor = function () {
  return NeuronTypes.find({});
}

Template.neuron_type_show.driver_lines = function () {
  return get_driver_lines(this);
}

Template.neuron_type_show.neuropiles = function () {
  return get_neuropiles(this);
}

Template.neuron_type_show.events({
  'click a.delete': function(e) {
    e.preventDefault();
    remove_neuron_type( this._id );
  }
});

// -------------

Template.neuropiles.neuropile_cursor = function () {
  return Neuropiles.find({});
}

Template.neuropile_show.driver_lines = function () {
  return get_driver_lines(this);
}

Template.neuropile_show.neuron_types = function () {
  return get_neuron_types(this);
}

Template.neuropile_show.events({
  'click a.delete': function(e) {
    e.preventDefault();
    remove_neuropile( this._id );
  }
});

// -------------

UI.body.getData = function () {
  return 'data';
};
