Template.binary_data_from_id_block.binary_data_from_id = ->
  if @_id
    # already a doc
    return this
  my_id = this
  if @valueOf
    # If we have "valueOf" function, "this" is boxed.
    my_id = @valueOf() # unbox it
  BinaryData.findOne my_id

insert_image_save_func = (info, template) ->
  fb = template.find("#insert_image")
  fo = fb.files
  s3_dirname = "/" + info.body_template_data.field_name
  S3.upload fo, s3_dirname, (error, result) ->
    if error?
      # FIXME: do something on error
      console.log "ERROR"
      return
    doc =
      name: fo[0].name
      lastModifiedDate: fo[0].lastModifiedDate
      type: info.body_template_data.field_name
      url: result.url
      secure_url: result.secure_url
      relative_url: result.relative_url

    BinaryData.insert doc, (error, _id) ->

      # FIXME: be more useful. E.g. hide a "saving... popup"
      if error?
        console.log "image_insert_callback with error:", error
        return
      data = info.body_template_data
      coll = window.get_collection_from_name(data.collection)
      orig = coll.findOne(_id: data.my_id)
      myarr = []
      myarr = orig[data.field_name]  if orig.hasOwnProperty(data.field_name)
      myarr.push _id
      t2 = {}
      t2[data.field_name] = myarr
      coll.update data["my_id"],
        $set: t2

      return

    return

  {}

Template.add_image_code.events "click .insert": (e, tmpl) ->
  e.preventDefault()
  Session.set "modal_info",
    title: "Insert image"
    body_template_name: "insert_image_dialog"
    body_template_data:
      my_id: @my_id
      collection: @collection
      field_name: "images"

  window.modal_save_func = insert_image_save_func
  $("#show_dialog_id").modal "show"
  return

Template.binary_data.binary_data_cursor = ->
  BinaryData.find {}
