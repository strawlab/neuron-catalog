Template.show_dialog.modal_info = function () {
    var tmp = Session.get("modal_info");
    return tmp;
}

Template.show_dialog.events({
  'click .delete': function(e) {
    e.preventDefault();
    info = Session.get("modal_info");
    jump_table[info.collection].remove(info.my_id);
    $("#show_dialog_id").modal('hide');
    var route_name = jump_table[info.collection].base_route;
    Router.go(route_name);
  }
});

open_insert_edit_dialog = function (modal_title) {
  // A general purpose dialog for inserting a new entry or editing an
  // existing entry.
  Session.set("modal_info", {modal_title: modal_title});
  $("#show_dialog_id").modal('show');
}

edit_driver_line = function(_id) {
  open_insert_edit_dialog("edit driver line "+_id);
}

var jump_table = {
  'DriverLines': {'remove': function (x) { remove_driver_line(x); },
		  'edit':   function (x) { edit_driver_line(x); },
		  'delete_template_name': "driver_line_show_brief",
		  'base_route': 'driver_lines'
		 },
  'NeuronTypes': {'remove': function (x) { remove_neuron_type(x); },
		  'edit':   function (x) { edit_neuron_type(x); },
		  'delete_template_name': "neuron_type_show_brief",
		  'base_route': 'neuron_types'
		 },
  'Neuropiles':  {'remove': function (x) { remove_neuropile(x);   },
		  'edit':   function (x) { edit_neuropile(x); },
		  'delete_template_name': "neuropile_show_brief",
		  'base_route': 'neuropiles'
		 }
}

Template.edit_delete_buttons.events({
  'click a.edit': function(e) {
    e.preventDefault();
    jump_table[this.collection].edit(this.my_id);
  },
  'click a.delete': function(e) {
    e.preventDefault();
    //remove_driver_line(this.my_id);
    Session.set("modal_info", {title: "Do you want to delete this?",
			       collection: this.collection,
			       my_id: this.my_id,
			       body_template_name: jump_table[this.collection].delete_template_name,
			       body_template_data: this.my_id,
			       is_delete_modal: true
			      });
    $("#show_dialog_id").modal('show');
  }
});


// -------------

Template.driver_line_from_id_block.driver_line_from_id = function () {
  if (this._id) { // already a doc
    return this;
  }
  var my_id = this;
  if (this.valueOf) { // If we have "valueOf" function, "this" is boxed.
    my_id = this.valueOf(); // unbox it
  }
  return DriverLines.findOne(my_id);
}

Template.neuron_type_from_id_block.neuron_type_from_id = function () {
  if (this._id) { // already a doc
    return this;
  }
  var my_id = this;
  if (this.valueOf) { // If we have "valueOf" function, "this" is boxed.
    my_id = this.valueOf(); // unbox it
  }
  return NeuronTypes.findOne(my_id);
}

Template.neuropile_from_id_block.neuropile_from_id = function () {
  if (this._id) { // already a doc
    return this;
  }
  var my_id = this;
  if (this.valueOf) { // If we have "valueOf" function, "this" is boxed.
    my_id = this.valueOf(); // unbox it
  }
  return Neuropiles.findOne(my_id);
}

// -------------

Template.driver_lines.driver_line_cursor = function () {
  return DriverLines.find({});
}

Template.driver_lines.events({
  'click a.insert': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new driver line");
  }
});

// -------------

Template.neuron_types.events({
  'click a.insert': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new neuron type");
  }
});

Template.neuron_types.neuron_type_cursor = function () {
  return NeuronTypes.find({});
}

// -------------

Template.neuropiles.events({
  'click a.insert': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new neuropile");
  }
});

Template.neuropiles.neuropile_cursor = function () {
  return Neuropiles.find({});
}

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
