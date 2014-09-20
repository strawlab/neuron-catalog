Template.driver_line_insert.neuron_types = ->
  NeuronTypes.find()

Template.driver_line_insert.neuropils = ->
  Neuropils.find()

driver_line_insert_callback = (error, _id) ->

  # FIXME: be more useful. E.g. hide a "saving... popup"
  console.log "driver_line_insert_callback with error:", error  if error
  return

@save_driver_line = (info, template) ->
  result = {}
  doc = {}
  errors = []

  # parse
  doc.name = template.find(".name").value
  errors.push "Name is required."  if doc.name.length < 1
  doc.neuron_types = []
  r1 = template.findAll(".neuron_types")
  for i of r1
    node = r1[i]
    doc.neuron_types.push node.id  if node.checked
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
  DriverLines.insert doc, driver_line_insert_callback
  result

Template.edit_driver_lines.driver_lines = ->
  result = []
  collection = window.get_collection_from_name(@collection_name)
  myself = collection.findOne(_id: @my_id)
  DriverLines.find().forEach (doc) ->
    doc.is_checked = false
    doc.is_checked = true  unless myself.best_driver_lines.indexOf(doc._id) is -1  if myself.hasOwnProperty("best_driver_lines")
    result.push doc
    return

  result

Template.driver_line_show.events
  "click .edit-neuron-types": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit neuron types"
      body_template_name: window.jump_table["DriverLines"].edit_neuron_types_template_name
      body_template_data:
        my_id: @_id
        collection_name: "DriverLines"

    window.modal_save_func = edit_neuron_types_save_func
    $("#show_dialog_id").modal "show"
    return

  "click .edit-neuropils": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit neuropils"
      body_template_name: window.jump_table["DriverLines"].edit_neuropils_template_name
      body_template_data:
        my_id: @_id
        collection_name: "DriverLines"

    window.modal_save_func = edit_neuropils_save_func
    $("#show_dialog_id").modal "show"
    return

@edit_driver_lines_save_func = (info, template) ->
  driver_lines = []
  my_id = Session.get("modal_info").body_template_data.my_id
  r1 = template.findAll(".driver_lines")
  for i of r1
    node = r1[i]
    driver_lines.push node.id  if node.checked
  coll_name = Session.get("modal_info").body_template_data.collection_name
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      best_driver_lines: driver_lines

  {}

Template.driver_lines.driver_line_cursor = ->
  DriverLines.find {}

Template.driver_lines.events "click .insert": (e) ->
  e.preventDefault()
  coll = "DriverLines"
  Session.set "modal_info",
    title: "Add driver line"
    collection: coll
    body_template_name: window.jump_table[coll].insert_template_name

  window.modal_save_func = window.jump_table[coll].save
  $("#show_dialog_id").modal "show"
  return
