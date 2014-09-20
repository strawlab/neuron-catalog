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
