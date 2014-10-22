Template.neuropil_from_id_block.neuropil_from_id = ->
  if @_id
    # already a doc
    return this

  my_id = this
  if @valueOf
    # If we have "valueOf" function, "this" is boxed.
    my_id = @valueOf() # unbox it

  Neuropils.findOne my_id

neuropil_insert_callback = (error, _id) ->
  # FIXME: be more useful. E.g. hide a "saving... popup"
  if error?
    console.log "neuropil_insert_callback with error:", error
    return

# @remove_neuropil is defined in ../vpn.coffee

@save_neuropil = (info, template) ->
  result = {}

  # parse
  name = template.find(".name").value

  # find errors
  errors = []
  errors.push "Name is required."  if name.length < 1

  # report errors
  if errors.length > 0
    if errors.length is 1
      result.error = "Error: " + errors[0]
    else result.error = "Errors: " + errors.join(", ")  if errors.length > 1
    return result

  # save result
  Neuropils.insert
    name: name
  , neuropil_insert_callback
  result

Template.edit_neuropils.neuropils = ->
  result = []
  collection = window.get_collection_from_name(@collection_name)
  myself = collection.findOne(_id: @my_id)
  Neuropils.find().forEach (doc) ->
    if myself.neuropils.indexOf(doc._id) is -1
      doc.unspecific_is_checked = false
    else
      doc.unspecific_is_checked = true
    doc.output_is_checked = false
    doc.input_is_checked = false

    if myself.output_neuropils? and myself.output_neuropils.indexOf(doc._id) != -1
      doc.output_is_checked = true
    if myself.input_neuropils? and myself.input_neuropils.indexOf(doc._id) != -1
      doc.input_is_checked = true

    result.push doc
    return

  result

fill_from = (selector, template, neuropil_type, result) ->
  for node of template.findAll(selector)
    if node.checked
      if !result.hasOwnProperty(node.id)
        result[node.id] = []
      result[node.id].push neuropil_type
  return

dict2arr = (neuropils) ->
  result = []
  for _id, tarr of neuropils
    result.push( [_id, tarr] )
  result

@edit_neuropils_save_func = (info, template) ->
  my_id = Session.get("modal_info").body_template_data.my_id

  neuropils = {}
  fill_from(".neuropils",template,"unspecified",neuropils)
  fill_from(".output-neuropils",template,"output",neuropils)
  fill_from(".input-neuropils",template,"input",neuropils)
  neuropils = dict2arr(neuropils)

  coll_name = Session.get("modal_info").body_template_data.collection_name
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      neuropils: neuropils
  {}

Template.neuropil_show.driver_lines_referencing_me = ->
  DriverLines.find neuropils: @_id

Template.neuropil_table.driver_lines_referencing_me = Template.neuropil_show.driver_lines_referencing_me
Template.neuropil_show.neuron_types_referencing_me = ->
  NeuronTypes.find neuropils: @_id

Template.neuropil_table.neuron_types_referencing_me = Template.neuropil_show.neuron_types_referencing_me

Template.neuropils.events "click .insert": (e) ->
  e.preventDefault()
  coll = "Neuropils"
  Session.set "modal_info",
    title: "Add neuropil"
    collection: coll
    body_template_name: window.jump_table[coll].insert_template_name
    is_save_modal: true

  window.modal_save_func = window.jump_table[coll].save
  $("#show_dialog_id").modal "show"
  return

Template.neuropils.neuropil_cursor = ->
  Neuropils.find {}
