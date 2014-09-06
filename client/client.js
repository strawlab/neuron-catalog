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

var jump_table = {
  'DriverLines': {'remove': function (x) { remove_driver_line(x); },
		  'edit':   function (x) { edit_driver_line(x); }
		 },
  'NeuronTypes': {'remove': function (x) { remove_neuron_type(x); },
		  'edit':   function (x) { edit_neuron_type(x); }
		 },
  'Neuropiles':  {'remove': function (x) { remove_neuropile(x);   },
		  'edit':   function (x) { edit_neuropile(x); }
		 }
}

Template.edit_delete_buttons.events({
  'click button.edit': function(e) {
    e.preventDefault();
    jump_table[this.collection].edit(this.my_id);
  },
  'click button.delete': function(e) {
    e.preventDefault();
    //open_confirm_dialog("Do you want to delete item?"); // TODO XXX FIXME add this
    jump_table[this.collection].remove(this.my_id);
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
  'click a.add': function(e) {
    e.preventDefault();
    open_insert_edit_dialog("Add new driver line");
  }
});

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
