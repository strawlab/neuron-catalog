// --------------------------------------------
// session variables
Session.setDefault('editing_add_synonym', null);
Session.setDefault("modal_info",null);
var modal_save_func = null;

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
    var result = modal_save_func(info,template);
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
		  'save': function(info, template) { return save_driver_line(info,template); },
		  'insert_template_name': "driver_line_insert",
		  'delete_template_name': "driver_line_show_brief",
		  'element_route': 'driver_line_show',
		  'base_route': 'driver_lines',
		  'edit_neuropiles_template_name':'edit_neuropiles',
		  'collection':DriverLines
		 },
  'NeuronTypes': {'remove': function (x) { return remove_neuron_type(x); },
		  'save': function(info, template) { return save_neuron_type(info,template); },
		  'insert_template_name': "neuron_type_insert",
		  'delete_template_name': "neuron_type_show_brief",
		  'element_route': 'neuron_type_show',
		  'base_route': 'neuron_types',
		  'edit_neuropiles_template_name':'edit_neuropiles',
		  'collection':NeuronTypes
		 },
  'Neuropiles':  {'remove': function (x) { return remove_neuropile(x); },
		  'save': function(info, template) { return save_neuropile(info,template); },
		  'insert_template_name': "neuropile_insert",
		  'delete_template_name': "neuropile_show_brief",
		  'element_route': 'neuropile_show',
		  'base_route': 'neuropiles',
		  'collection':Neuropiles
		 }
}

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
    modal_save_func = null;
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
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "DriverLines";
    Session.set("modal_info", {title: "Add driver line",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
  }
});

// -------------

Template.neuron_types.events({
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "NeuronTypes";
    Session.set("modal_info", {title: "Add neuron type",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
  }
});

Template.neuron_types.neuron_type_cursor = function () {
  return NeuronTypes.find({});
}

// -------------

Template.neuropiles.events({
  'click .insert': function(e) {
    e.preventDefault();
    var coll = "Neuropiles";
    Session.set("modal_info", {title: "Add neuropile",
			       collection: coll,
			       body_template_name: jump_table[coll].insert_template_name
			      });
    modal_save_func = jump_table[coll].save;
    $("#show_dialog_id").modal('show');
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

// ------------

Template.neuron_type_show.driver_lines_referencing_me = function () {
  return DriverLines.find( {'neuron_types': this._id} );
}

Template.neuropile_show.driver_lines_referencing_me = function () {
  return DriverLines.find( {'neuropiles': this._id} );
}

Template.neuropile_show.neuron_types_referencing_me = function () {
  return NeuronTypes.find( {'neuropiles': this._id} );
}

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
  'click .edit-neuropiles': function(e) {
    e.preventDefault();
    Session.set("modal_info", {title: "Edit neuropiles",
			       body_template_name: jump_table["NeuronTypes"].edit_neuropiles_template_name,
			       body_template_data: {neuron_type_id:this._id}
			      });

    edit_save_cb = function(error, _id) {
      // FIXME: be more useful. E.g. hide a "saving... popup"
      if (error) {
	console.log("edit save: callback with error:",error);
      }
    }

    modal_save_func = function (info, template) {
      var neuropiles=[];
      var my_id = Session.get("modal_info").body_template_data.neuron_type_id

      var r1 = template.findAll(".neuropiles");
      for (i in r1) {
	node = r1[i];
	if (node.checked) {
	    neuropiles.push( node.id );
	}
      }
      NeuronTypes.update(my_id, {$set:{'neuropiles':neuropiles}}, edit_save_cb);
      return {};
    }
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

Template.edit_neuropiles.neuropiles = function () {
  var result = [];
  var myself = NeuronTypes.findOne({_id:this.neuron_type_id});
  Neuropiles.find().forEach( function (doc) {
    if (myself.neuropiles.indexOf(doc._id)==-1) {
      doc.is_checked = false;
    } else {
      doc.is_checked = true;
    }
    result.push( doc );
  });
  return result;
}

// -------------

Template.driver_line_insert.neuron_types = function () {
  return NeuronTypes.find();
}

Template.driver_line_insert.neuropiles = function () {
  return Neuropiles.find();
}

driver_line_insert_callback = function(error, _id) {
  // FIXME: be more useful. E.g. hide a "saving... popup"
  if (error) {
    console.log("driver_line_insert_callback with error:",error);
  }
}

save_driver_line = function(info,template) {
  var result = {};
  var doc = {};
  var errors = [];

  // parse
  doc.name = template.find(".name").value;
  if (doc.name.length<1) {
    errors.push("Name is required.");
  }

  doc.neuron_types = [];
  var r1 = template.findAll(".neuron_types");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      doc.neuron_types.push( node.id );
    }
  }

  doc.neuropiles = [];
  var r1 = template.findAll(".neuropiles");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      doc.neuropiles.push( node.id );
    }
  }

  // report errors
  if (errors.length>0) {
    if (errors.length==1) {
      result.error="Error: " + errors[0];
    } else if (errors.length>1) {
      result.error="Errors: " + errors.join(", ");
    }
    return result;
  }

  // save result
  DriverLines.insert(doc, driver_line_insert_callback);
  return result;
}

// -------------

Template.neuron_type_insert.driver_lines = function () {
  return DriverLines.find();
}

Template.neuron_type_insert.neuropiles = function () {
  return Neuropiles.find();
}

neuron_type_insert_callback = function(error, _id) {
  // FIXME: be more useful. E.g. hide a "saving... popup"
  if (error) {
    console.log("neuron_type_insert_callback with error:",error);
  }
}

save_neuron_type = function(info,template) {
  var result = {};
  var doc = {};
  var errors = [];

  // parse
  doc.name = template.find(".name").value;
  if (doc.name.length<1) {
    errors.push("Name is required.");
  }

  /*
  doc.best_driver_lines = [];
  var r1 = template.findAll(".best_driver_lines");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      doc.best_driver_lines.push( node.id );
    }
  }
  */

  doc.neuropiles = [];
  var r1 = template.findAll(".neuropiles");
  for (i in r1) {
    node = r1[i];
    if (node.checked) {
      doc.neuropiles.push( node.id );
    }
  }

  // report errors
  if (errors.length>0) {
    if (errors.length==1) {
      result.error="Error: " + errors[0];
    } else if (errors.length>1) {
      result.error="Errors: " + errors.join(", ");
    }
    return result;
  }

  // save result
  NeuronTypes.insert(doc, neuron_type_insert_callback);
  return result;
}

// -------------

neuropile_insert_callback = function(error, _id) {
  // FIXME: be more useful. E.g. hide a "saving... popup"
  if (error) {
    console.log("neuropile_insert_callback with error:",error);
  }
}

save_neuropile = function(info,template) {
  var result = {};

  // parse
  var name = template.find(".name").value;

  // find errors
  var errors = [];
  if (name.length<1) {
    errors.push("Name is required.");
  }

  // report errors
  if (errors.length>0) {
    if (errors.length==1) {
      result.error="Error: " + errors[0];
    } else if (errors.length>1) {
      result.error="Errors: " + errors.join(", ");
    }
    return result;
  }

  // save result
  Neuropiles.insert({"name":name}, neuropile_insert_callback);
  return result;
}

// -------------

UI.body.getData = function () {
  return 'data';
};

// -------
