editing_add_synonym = new ReactiveVar(null)

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

# ---- Template.EditNeuronTypesDialog -----------------

Template.EditNeuronTypesDialog.helpers
  neuron_types: ->
    result = []
    collection = window.get_collection_from_name(@collection_name)
    myself = collection.findOne(_id: @my_id)
    NeuronTypes.find({},{sort:neuron_types_sort}).forEach (doc) ->
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

    editing_add_synonym.set(null)
    return

  cancel: ->
    editing_add_synonym.set(null)
    return
)

Template.neuron_type_show.events
  "click .add_synonym": (e, tmpl) ->

    # inspiration: meteor TODO app
    editing_add_synonym.set(@_id)
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

  "click .edit-best-driver-lines": (event, template) ->
    event.preventDefault()
    send_coll = "NeuronTypes"
    send_id = @_id
    data =
      collection_name: send_coll
      my_id: send_id
    window.dialog_template = bootbox.dialog
      title: "Edit best driver lines for neuron type "+@name
      message: window.renderTmp(Template.EditDriverLinesDialog,data)
      buttons:
        close:
          label: "Close"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            edit_driver_lines_save_func(dialog_template, send_coll, send_id)

  "click .edit-brain-regions": (event,template) ->
    event.preventDefault()
    send_coll = "NeuronTypes"
    send_id = @_id
    data =
      collection_name: send_coll
      my_id: send_id
    window.dialog_template = bootbox.dialog
      title: "Edit brain regions for neuron type "+@name
      message: window.renderTmp(Template.EditBrainRegionsDialog,data)
      buttons:
        close:
          label: "Close"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            edit_brain_regions_save_func(dialog_template, send_coll, send_id)

@edit_neuron_types_save_func = (template,coll_name,my_id) ->
  neuron_types = []
  for node in template.find(".neuron_types")
    neuron_types.push node.id  if node.checked
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      neuron_types: neuron_types

Template.neuron_type_show.helpers
  adding_synonym: ->
    editing_add_synonym.get() == @_id

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
      title: "Add a new neuron type"
      message: window.renderTmp(Template.AddNeuronTypeDialog)
      buttons:
        close:
          label: "Close"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            result = save_neuron_type(dialog_template)
            if result.errors
              bootbox.alert('Errors: '+result.errors.join(", "))
    window.dialog_template.on("shown.bs.modal", ->
      $(".name").focus()
    )
    window.dialog_template.on("submit", ->
      window.dialog_template.find(".btn-primary").click()
      false
    )

Template.neuron_types.helpers
  neuron_type_cursor: ->
    NeuronTypes.find {},{sort:neuron_types_sort}
