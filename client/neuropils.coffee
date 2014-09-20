neuropil_insert_callback = (error, _id) ->
  # FIXME: be more useful. E.g. hide a "saving... popup"
  if error?
    console.log "neuropil_insert_callback with error:", error
    return

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
      doc.is_checked = false
    else
      doc.is_checked = true
    result.push doc
    return

  result

@edit_neuropils_save_func = (info, template) ->
  neuropils = []
  my_id = Session.get("modal_info").body_template_data.my_id
  r1 = template.findAll(".neuropils")
  for i of r1
    node = r1[i]
    neuropils.push node.id  if node.checked
  coll_name = Session.get("modal_info").body_template_data.collection_name
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      neuropils: neuropils

  {}
