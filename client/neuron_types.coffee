Template.neuron_type_insert.driver_lines = ->
  DriverLines.find()

Template.neuron_type_insert.neuropils = ->
  Neuropils.find()

neuron_type_insert_callback = (error, _id) ->
  if error?
    # FIXME: be more useful. E.g. hide a "saving... popup"
    console.log "neuron_type_insert_callback with error:", error
    return

@save_neuron_type = (info, template) ->
  result = {}
  doc = {}
  errors = []

  # parse
  doc.name = template.find(".name").value
  errors.push "Name is required."  if doc.name.length < 1

  doc.best_driver_lines = []
  # r1 = template.findAll(".best_driver_lines")
  # for i of r1
  #   node = r1[i]
  #   doc.best_driver_lines.push node.id  if node.checked

  doc.neuropils = []
  r1 = template.findAll(".neuropils")
  for i of r1
    node = r1[i]
    doc.neuropils.push node.id  if node.checked

  # report errors
  if errors.length > 0
    if errors.length is 1
      result.error = "Error: " + errors[0]
    else result.error = "Errors: " + errors.join(", ")  if errors.length > 1
    return result

  # save result
  NeuronTypes.insert doc, neuron_type_insert_callback
  result

Template.edit_neuron_types.neuron_types = ->
  result = []
  collection = window.get_collection_from_name(@collection_name)
  myself = collection.findOne(_id: @my_id)
  NeuronTypes.find().forEach (doc) ->
    if myself.neuron_types.indexOf(doc._id) is -1
      doc.is_checked = false
    else
      doc.is_checked = true
    result.push doc
    return

  result

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
    activateInput tmpl.find("#edit_synonym_input")
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
      title: "Edit best driver lines"
      body_template_name: window.jump_table["NeuronTypes"].edit_driver_lines_template_name
      body_template_data:
        my_id: @_id
        collection_name: "NeuronTypes"

    window.modal_save_func = edit_driver_lines_save_func
    $("#show_dialog_id").modal "show"
    return

  "click .edit-neuropils": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit neuropils"
      body_template_name: window.jump_table["NeuronTypes"].edit_neuropils_template_name
      body_template_data:
        my_id: @_id
        collection_name: "NeuronTypes"

    window.modal_save_func = edit_neuropils_save_func
    $("#show_dialog_id").modal "show"
    return
