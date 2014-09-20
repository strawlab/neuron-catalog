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