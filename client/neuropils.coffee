Template.neuropil_from_id_block.neuropil_from_id = ->
# We can get called 3 ways:
# 1) From something that keeps track of what expression type is in the neuropil.
# 2) Already as a full document from the database.
# 3) As just an id to the neuropil.
  if @type?
    # This is case #1 described above.
    # object with keys ["_id", "type"]:
    my_id = @_id
    my_types = @type
    insert_types = true
  else
    insert_types = false
    if @_id?
      # This is case #2 described above.
      # already a doc
      return this

    # This is case #3 described above.
    my_id = this

    if @valueOf
      # If we have "valueOf" function, "this" is boxed.
      my_id = @valueOf() # unbox it

  result = Neuropils.findOne my_id
  if insert_types
    result.my_types = my_types
  result

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
    doc.unspecific_is_checked = false
    doc.output_is_checked = false
    doc.input_is_checked = false

    if myself.neuropils_unspecific? and myself.neuropils_unspecific.indexOf(doc._id) != -1
      doc.unspecific_is_checked = true
    if myself.neuropils_output? and myself.neuropils_output.indexOf(doc._id) != -1
      doc.output_is_checked = true
    if myself.neuropils_input? and myself.neuropils_input.indexOf(doc._id) != -1
      doc.input_is_checked = true

    result.push doc
    return

  result

fill_from = (selector, template, neuropil_type, result) ->
  for node in template.findAll(selector)
    console.log node
    if node.checked
      if !result.hasOwnProperty(node.id)
        result[node.id] = []
      result[node.id].push neuropil_type
      console.log "adding ",neuropil_type,"to",node.id
  console.log "new result",result
  return

dict2arr = (neuropils) ->
  result = []
  for _id, tarr of neuropils
    result.push( {"_id":_id, "type":tarr} )
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
  DriverLines.find neuropils:
    $elemMatch:
      _id: @_id

Template.neuropil_table.driver_lines_referencing_me = Template.neuropil_show.driver_lines_referencing_me
Template.neuropil_show.neuron_types_referencing_me = ->
  NeuronTypes.find neuropils:
    $elemMatch:
      _id: @_id

Template.neuropil_table.neuron_types_referencing_me = Template.neuropil_show.neuron_types_referencing_me

Template.neuropils.events "click .insert": (e) ->
  e.preventDefault()
  coll = "Neuropils"
  Session.set "modal_info",
    title: "Add neuropil"
    collection: coll
    body_template_name: "neuropil_insert"
    is_save_modal: true

  window.modal_save_func = window.jump_table[coll].save
  $("#show_dialog_id").modal "show"
  return

Template.neuropils.neuropil_cursor = ->
  Neuropils.find {}
