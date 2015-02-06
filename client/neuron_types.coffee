driver_lines_sort = {}
driver_lines_sort[window.get_sort_key("DriverLines")] = 1
neuron_types_sort = {}
neuron_types_sort[window.get_sort_key("NeuronTypes")]=1
brain_regions_sort = {}
brain_regions_sort[window.get_sort_key("BrainRegions")] = 1

# ---- Template.neuron_type_from_id_block ---------------

Template.neuron_type_from_id_block.helpers
  neuron_type_from_id: ->
    if @_id
      # already a doc
      return this
    my_id = this
    if @valueOf
      # If we have "valueOf" function, "this" is boxed.
      my_id = @valueOf() # unbox it
    NeuronTypes.findOne my_id

# ---- Template.AddNeuronTypeDialog ---------------

Template.AddNeuronTypeDialog.helpers
  driver_lines: ->
    DriverLines.find({},{'sort':driver_lines_sort})

  brain_regions: ->
    BrainRegions.find({},{'sort':brain_regions_sort})

neuron_type_insert_callback = (error, _id) ->
  if error?
    console.error "neuron_type_insert_callback with error:", error
    bootbox.alert "Saving failed: "+error
    return

# @remove_neuron_type is defined in ../neuron-catalog.coffee

@save_neuron_type = (template) ->
  result = {}
  doc = {}
  errors = []

  # parse
  if !template.find?
    console.error "no template.find"
    return
  doc.name = template.find(".name")[0].value
  errors.push "Name is required."  if doc.name.length < 1

  doc.best_driver_lines = []

  brain_regions = {}
  brain_region_fill_from_jquery(".brain_regions-unspecified",template,"unspecified",brain_regions)
  brain_region_fill_from_jquery(".brain_regions-output",template,"output",brain_regions)
  brain_region_fill_from_jquery(".brain_regions-input",template,"input",brain_regions)
  brain_regions = brain_region_dict2arr(brain_regions)

  doc.brain_regions = brain_regions
  doc.tags = []
  doc.comments = []
  doc.images = []
  doc.synonyms = []
  doc.flycircuit_idids = []

  # report errors
  if errors.length > 0
    result.errors = errors
    return result

  # save result
  NeuronTypes.insert doc, neuron_type_insert_callback
  result

# ---- Template.edit_neuron_types -----------------

Template.edit_neuron_types.helpers
  neuron_types: ->
    result = []
    collection = window.get_collection_from_name(@collection_name)
    myself = collection.findOne(_id: @my_id)
    NeuronTypes.find({},{'sort':neuron_types_sort}).forEach (doc) ->
      if myself.neuron_types.indexOf(doc._id) is -1
        doc.is_checked = false
      else
        doc.is_checked = true
      result.push doc
      return

    result

# ---- Template.neuron_type_show ---------------

Template.neuron_type_show.events window.okCancelEvents("#edit_synonym_input",
  ok: (value) ->
    NeuronTypes.update @_id,
      $addToSet:
        synonyms: value

    Session.set "editing_add_synonym", null
    return

  cancel: ->
    Session.set "editing_add_synonym", null
    return
)

Template.neuron_type_show.events
  "click .add_synonym": (e, tmpl) ->

    # inspiration: meteor TODO app
    Session.set "editing_add_synonym", @_id
    Deps.flush() # update DOM before focus
    window.activateInput tmpl.find("#edit_synonym_input")
    return

  "click .remove": (evt) ->
    synonym = @name
    id = @_id
    evt.target.parentNode.style.opacity = 0

    # wait for CSS animation to finish
    Meteor.setTimeout (->
      NeuronTypes.update
        _id: id
      ,
        $pull:
          synonyms: synonym

      return
    ), 300
    return

  "click .edit-driver-lines": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit best driver lines for neuron type "+@name
      body_template_name: "edit_driver_lines"
      body_template_data:
        my_id: @_id
        collection_name: "NeuronTypes"
      is_save_modal: true

    window.modal_save_func = edit_driver_lines_save_func
    $("#show_dialog_id").modal "show"
    return

  "click .edit-brain_regions": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit brain_regions for neuron type "+@name
      body_template_name: "edit_brain_regions"
      body_template_data:
        my_id: @_id
        collection_name: "NeuronTypes"
      is_save_modal: true

    window.modal_save_func = edit_brain_regions_save_func
    $("#show_dialog_id").modal "show"
    return

@edit_neuron_types_save_func = (info, template) ->
  neuron_types = []
  my_id = Session.get("modal_info").body_template_data.my_id
  r1 = template.findAll(".neuron_types")
  for i of r1
    node = r1[i]
    neuron_types.push node.id  if node.checked
  coll_name = Session.get("modal_info").body_template_data.collection_name
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      neuron_types: neuron_types

  {}

Template.neuron_type_show.helpers
  adding_synonym: ->
    Session.equals "editing_add_synonym", @_id

  synonym_dicts: ->
    result = []
    for i of @synonyms
      tmp =
        name: @synonyms[i]
        _id: @_id

      result.push tmp
    result

  driver_lines_referencing_me: ->
    DriverLines.find neuron_types: @_id

# ---- Template.neuron_types ---------------

Template.neuron_types.events
  "click .insert": (event, template) ->
    coll = "NeuronTypes"
    event.preventDefault()
    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.AddNeuronTypeDialog)
      buttons:
        close:
          label: "Close"
          className: "btn-default"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            result = save_neuron_type(dialog_template)
            if result.errors
              bootbox.alert('Errors: '+result.errors.join(", "))

Template.neuron_types.helpers
  neuron_type_cursor: ->
    NeuronTypes.find {},{'sort':neuron_types_sort}
