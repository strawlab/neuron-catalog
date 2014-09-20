// -------------
// font awesome (see
// https://github.com/nate-strauser/meteor-font-awesome/blob/master/load.js )

var head = document.getElementsByTagName('head')[0];

//Generate a style tag
var style = document.createElement('link');
style.type = 'text/css';
style.rel = "stylesheet";
style.href = '/css/font-awesome.min.css';

head.appendChild(style);

// -------------

Meteor.subscribe('driver_lines');
Meteor.subscribe('neuron_types');
Meteor.subscribe('neuropils');
Meteor.subscribe('binary_data');

// --------------------------------------------
// session variables
Session.setDefault('editing_name', null);
Session.setDefault('editing_add_synonym', null);
Session.setDefault("modal_info",null);
Session.setDefault("comment_preview_mode",false);
Session.setDefault("comment_preview_html",null);

window.modal_save_func = null;


// --------------------------------------------
// helper functions
window.get_collection_from_name = function(name) {
  var coll;
  if (name=="DriverLines") {
    coll = DriverLines;
  } else if (name=="NeuronTypes") {
    coll = NeuronTypes;
  } else if (name=="Neuropils") {
    coll = Neuropils;
  } else if (name=="BinaryData") {
    coll = BinaryData;
  }
  return coll;
}

// --------------------------------------------
// from: meteor TODO app

// Returns an event map that handles the "escape" and "return" keys and
// "blur" events on a text input (given by selector) and interprets them
// as "ok" or "cancel".
var okCancelEvents = function (selector, callbacks) {
  var ok = callbacks.ok || function () {};
  var cancel = callbacks.cancel || function () {};

  var events = {};
  events['keyup '+selector+', keydown '+selector+', focusout '+selector] =
    function (evt) {
      if (evt.type === "keydown" && evt.which === 27) {
        // escape = cancel
        cancel.call(this, evt);

      } else if (evt.type === "keyup" && evt.which === 13 ||
                 evt.type === "focusout") {
        // blur/return/enter = ok/submit if non-empty
        var value = String(evt.target.value || "");
        if (value)
          ok.call(this, value, evt);
        else
          cancel.call(this, evt);
      }
    };

  return events;
};

var activateInput = function (input) {
  input.focus();
  input.select();
};
// --------------------------------------------


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
  },
  'click .save': function(event, template) {
    event.preventDefault();
    info = Session.get("modal_info");
    var result = window.modal_save_func(info,template);
    if (result.error) {
      info.error = result.error;
      Session.set("modal_info",info);
    } else {
      $("#show_dialog_id").modal('hide');
    }
  }
});

var jump_table = {
  'DriverLines': {'remove': function (x) { return remove_driver_line(x); },
		  'save': function(info, template) { return this.save_driver_line(info,template); },
		  'insert_template_name': "driver_line_insert",
		  'delete_template_name': "driver_line_show_brief",
		  'element_route': 'driver_line_show',
		  'base_route': 'driver_lines',
		  'edit_neuron_types_template_name':'edit_neuron_types',
		  'edit_neuropils_template_name':'edit_neuropils'
		 },
  'NeuronTypes': {'remove': function (x) { return remove_neuron_type(x); },
		  'save': function(info, template) { return this.save_neuron_type(info,template); },
		  'insert_template_name': "neuron_type_insert",
		  'delete_template_name': "neuron_type_show_brief",
		  'element_route': 'neuron_type_show',
		  'base_route': 'neuron_types',
		  'edit_driver_lines_template_name':'edit_driver_lines',
		  'edit_neuropils_template_name':'edit_neuropils'
		 },
  'Neuropils':  {'remove': function (x) { return remove_neuropil(x); },
		  'save': function(info, template) { return this.save_neuropil(info,template); },
		  'insert_template_name': "neuropil_insert",
		  'delete_template_name': "neuropil_show_brief",
		  'element_route': 'neuropil_show',
		  'base_route': 'neuropils'
		 },
  'BinaryData': {'remove': function (x) { return remove_binary_data(x); },
		 'delete_template_name':'binary_data_show_brief',
		 'base_route': 'binary_data',
		 }
}

Template.name_field.editing_name = function () {
  var d = Session.get('editing_name');
  if (d==null) {
    return false;
  }
  if (this.my_id == d.my_id & this.collection == d.collection) {
    return true;
  }
  return false;
}

Template.name_field.events({
  'click .edit-name': function(e,tmpl) {
    Session.set('editing_name', tmpl.data);
    Deps.flush(); // update DOM before focus
    var ni = tmpl.find("#name_input");
    ni.value = this.name;
    activateInput(ni);
  }});
Template.name_field.events(okCancelEvents(
    '#name_input',
    {
      ok: function (value) {
	var coll = window.get_collection_from_name(this.collection);
	coll.update(this.my_id, {$set :{"name":value}});
	Session.set('editing_name', null);
      },
      cancel: function () {
	Session.set('editing_name', null);
      }
    }));

Template.delete_button.events({
  'click .delete': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Do you want to delete this?",
			       collection: this.collection,
			       my_id: this.my_id,
			       body_template_name: jump_table[this.collection].delete_template_name,
			       body_template_data: this.my_id,
			       is_delete_modal: true
			      });
    window.modal_save_func = null;
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

Template.binary_data_from_id_block.binary_data_from_id = function () {
  if (this._id) { // already a doc
    return this;
  }
  var my_id = this;
  if (this.valueOf) { // If we have "valueOf" function, "this" is boxed.
    my_id = this.valueOf(); // unbox it
  }
  return BinaryData.findOne(my_id);
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

Template.neuropil_from_id_block.neuropil_from_id = function () {
  if (this._id) { // already a doc
    return this;
  }
  var my_id = this;
  if (this.valueOf) { // If we have "valueOf" function, "this" is boxed.
    my_id = this.valueOf(); // unbox it
  }
  return Neuropils.findOne(my_id);
}

// -------------

Template.driver_lines.driver_line_cursor = function () {
  return DriverLines.find({});
}

Template.driver_lines.events({
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "DriverLines";
    Session.set("modal_info", {title: "Add driver line",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    window.modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
  }
});


// -------------

Template.binary_data.binary_data_cursor = function () {
  return BinaryData.find({});
}

// -------------

Template.neuron_types.events({
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "NeuronTypes";
    Session.set("modal_info", {title: "Add neuron type",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    window.modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
  }
});

Template.neuron_types.neuron_type_cursor = function () {
  return NeuronTypes.find({});
}

// -------------

Template.neuropils.events({
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "Neuropils";
    Session.set("modal_info", {title: "Add neuropil",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    window.modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
  }
});

Template.neuropils.neuropil_cursor = function () {
  return Neuropils.find({});
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

Template.MyLayout.tab_attrs_binary_data = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='binary_data' || cur.route.name=='binary_data_show' ) {
    return {'class':"active"};
  }
}

Template.MyLayout.tab_attrs_neuron_types = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='neuron_types' || cur.route.name=='neuron_type_show') {
    return {'class':"active"};
  }
}

Template.MyLayout.tab_attrs_neuropils = function () {
  var cur = Router.current();
  if (cur && cur.route.name=='neuropils' || cur.route.name=='neuropil_show') {
    return {'class':"active"};
  }
}

// ------------

Template.neuron_type_show.driver_lines_referencing_me = function () {
  return DriverLines.find( {'neuron_types': this._id} );
}

Template.neuropil_show.driver_lines_referencing_me = function () {
  return DriverLines.find( {'neuropils': this._id} );
}

Template.neuropil_table.driver_lines_referencing_me = Template.neuropil_show.driver_lines_referencing_me;

Template.neuropil_show.neuron_types_referencing_me = function () {
  return NeuronTypes.find( {'neuropils': this._id} );
}
Template.neuropil_table.neuron_types_referencing_me = Template.neuropil_show.neuron_types_referencing_me;

// -------------
Template.neuron_type_show.adding_synonym = function () {
  return Session.equals('editing_add_synonym',this._id);
}

Template.neuron_type_show.synonym_dicts = function () {
  var result = [];
  for (i in this.synonyms) {
    var tmp = {'name':this.synonyms[i],
	       '_id':this._id};
    result.push(tmp);
  }
  return result;
}

edit_driver_lines_save_func = function (info, template) {
  var driver_lines=[];
  var my_id = Session.get("modal_info").body_template_data.my_id

  var r1 = template.findAll(".driver_lines");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      driver_lines.push( node.id );
    }
  }
  var coll_name = Session.get("modal_info").body_template_data.collection_name;
  var collection;
  if (coll_name=="DriverLines") {
    collection = DriverLines;
  } else if (coll_name=="NeuronTypes") {
    collection = NeuronTypes;
  }
  collection.update(my_id, {$set:{'best_driver_lines':driver_lines}});
  return {};
}

edit_neuron_types_save_func = function (info, template) {
  var neuron_types=[];
  var my_id = Session.get("modal_info").body_template_data.my_id

  var r1 = template.findAll(".neuron_types");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      neuron_types.push( node.id );
    }
  }
  var coll_name = Session.get("modal_info").body_template_data.collection_name;
  var collection;
  if (coll_name=="DriverLines") {
    collection = DriverLines;
  } else if (coll_name=="NeuronTypes") {
    collection = NeuronTypes;
  }
  collection.update(my_id, {$set:{'neuron_types':neuron_types}});
  return {};
}

edit_neuropils_save_func = function (info, template) {
  var neuropils=[];
  var my_id = Session.get("modal_info").body_template_data.my_id

  var r1 = template.findAll(".neuropils");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      neuropils.push( node.id );
    }
  }
  var coll_name = Session.get("modal_info").body_template_data.collection_name;
  var collection;
  if (coll_name=="DriverLines") {
    collection = DriverLines;
  } else if (coll_name=="NeuronTypes") {
    collection = NeuronTypes;
  }
  collection.update(my_id, {$set:{'neuropils':neuropils}});
  return {};
}

Template.driver_line_show.events({
  'click .edit-neuron-types': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Edit neuron types",
			       body_template_name: jump_table["DriverLines"].edit_neuron_types_template_name,
			       body_template_data: {my_id:this._id,
						    collection_name: "DriverLines"}
			      });

    window.modal_save_func = edit_neuron_types_save_func;
    $("#show_dialog_id").modal('show');
  },
  'click .edit-neuropils': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Edit neuropils",
			       body_template_name: jump_table["DriverLines"].edit_neuropils_template_name,
			       body_template_data: {my_id:this._id,
						    collection_name: "DriverLines"}
			      });

    window.modal_save_func = edit_neuropils_save_func;
    $("#show_dialog_id").modal('show');
  }
});

Template.neuron_type_show.events({
  'click .add_synonym': function(e,tmpl) {
    // inspiration: meteor TODO app
    Session.set('editing_add_synonym', this._id);
    Deps.flush(); // update DOM before focus
    activateInput(tmpl.find("#edit_synonym_input"));
  },
  'click .remove': function (evt) {
    var synonym = this.name;
    var id = this._id;

    evt.target.parentNode.style.opacity = 0;
    // wait for CSS animation to finish
    Meteor.setTimeout(function () {
      NeuronTypes.update({_id: id}, {$pull: {synonyms: synonym}});
    }, 300);
  },
  'click .edit-driver-lines': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Edit best driver lines",
			       body_template_name: jump_table["NeuronTypes"].edit_driver_lines_template_name,
			       body_template_data: {my_id:this._id,
						    collection_name:"NeuronTypes"}
			      });

    window.modal_save_func = edit_driver_lines_save_func;
    $("#show_dialog_id").modal('show');
  },
  'click .edit-neuropils': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Edit neuropils",
			       body_template_name: jump_table["NeuronTypes"].edit_neuropils_template_name,
			       body_template_data: {my_id:this._id,
						    collection_name:"NeuronTypes"}
			      });

    window.modal_save_func = edit_neuropils_save_func;
    $("#show_dialog_id").modal('show');
  }
});

Template.neuron_type_show.events(okCancelEvents(
  '#edit_synonym_input',
  {
    ok: function (value) {
      NeuronTypes.update(this._id, {$addToSet: {synonyms: value}});
      Session.set('editing_add_synonym', null);
    },
    cancel: function () {
      Session.set('editing_add_synonym', null);
    }
  }));

