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

Template.show_dialog.modal_title = function () {
  var tmp = Session.get("modal_info");
  if (tmp) return tmp.modal_title;
}

Template.show_dialog.modal_body = function () {
  return "modal body";
}

open_insert_edit_dialog = function (modal_title) {
  // A general purpose dialog for inserting a new entry or editing an
  // existing entry.
  Session.set("modal_info", {modal_title: modal_title});
  $("#show_dialog_id").modal("show");
}


Template.edit_delete_buttons.events({
  'click button.delete': function(e) {
    e.preventDefault();
//    open_confirm_dialog("Do you want to delete driver line XYZ?");
//    remove_driver_line( this._id );
  }
});


// -------------

Template.driver_lines.driver_line_cursor = function () {
  return DriverLines.find({});
}

Template.driver_lines.events({
  'click a.add': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new driver line");
  }
});

Template.driver_line_show.neuron_types = function () {
  return get_neuron_types(this);
}

Template.driver_line_show.neuropiles = function () {
  return get_neuropiles(this);
}

/*
Template.driver_line_show.events({
  'click button.delete': function(e) {
    e.preventDefault();
    open_confirm_dialog("Do you want to delete driver line XYZ?");
    remove_driver_line( this._id );
  }
});
*/

// -------------

Template.neuron_types.events({
  'click a.add': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new neuron type");
  }
});

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

Template.neuropiles.events({
  'click a.add': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new neuropile");
  }
});

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

// ------- tab layout stuff ----

Template.MyLayout.tab_attrs_home = function () {
  var current = Router.current();
  if (current && current.route.name=='home') {
    return {'class':"active"};
  }
}

Template.MyLayout.tab_attrs_driver_lines = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='driver_lines' || cur.route.name=='driver_line_show' ) {
    return {'class':"active"};
  }
}

Template.MyLayout.tab_attrs_neuron_types = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='neuron_types' || cur.route.name=='neuron_type_show') {
    return {'class':"active"};
  }
}

Template.MyLayout.tab_attrs_neuropiles = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='neuropiles' || cur.route.name=='neuropile_show') {
    return {'class':"active"};
  }
}

// -------------

UI.body.getData = function () {
  return 'data';
};
