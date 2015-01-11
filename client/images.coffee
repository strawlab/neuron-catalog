Session.setDefault "trigger_update", null

# ---- Template.binary_data_from_id_block -------------

enhance_image_doc = (doc) ->
  if not doc?
    return

  if doc.secure_url_notif?
    # already performed this check
    return doc

  url_lower = doc.secure_url.toLowerCase()
  if endsWith(url_lower,".tif") or endsWith(url_lower,".tiff")
    # see https://gist.github.com/jlong/2428561 for parser trick
    parser = document.createElement('a');
    parser.href = doc.secure_url
    path_parts = parser.pathname.split('/')
    [blank, bucket, images, fname] = path_parts
    pathname = [blank, bucket, 'cache', fname+'.jpg'].join('/')
    newurl = parser.protocol + '//' + parser.host + pathname
    doc.secure_url_notif = newurl
  else
    doc.secure_url_notif = doc.secure_url

  if doc.thumb_src?
    doc.has_thumb = true
  else
    doc.has_thumb = false
  doc

Template.binary_data_from_id_block.helpers
  binary_data_from_id: ->

    if @_id
      # already a doc
      return enhance_image_doc(this)
    my_id = this
    if @valueOf
      # If we have "valueOf" function, "this" is boxed.
      my_id = @valueOf() # unbox it
    enhance_image_doc(BinaryData.findOne(my_id))

# -------------------------------------------------------
Template.binary_data_show.helpers
  binary_data_type: ->
    @type.slice(0,-1)

  find_references: ->
    coll_types = ["DriverLines","NeuronTypes","Neuropils"]
    image_id = @_id
    query =
      images: image_id
    result = []
    for collname in coll_types
      coll = window.get_collection_from_name(collname)
      coll.find(query).forEach (doc) ->
        result.push {"collection":collname,"doc":doc,"my_id":doc._id}
    result

# -------------------------------------------------------

# @remove_binary_data is defined in ../neuron-catalog.coffee

link_image_save_func = (info, template) ->
  d = info.body_template_data
  coll = window.get_collection_from_name(d.collection_name)
  elements = template.findAll(".selected")
  myarr = []
  for item in elements
    myarr.push(item.id)

  t2 = {images:myarr}
  coll.update d.my_id,
    $set: t2

  return {}

insert_image_save_func = (info, template) ->
  # FIXME: disable save/cancel button
  fb = template.find("#insert_image")
  upload_files = fb.files
  # FIXME: assert size(upload_files)==1
  s3_dirname = "/images"
  $("#show_upload_progress_id").modal("show")

  S3.upload upload_files, s3_dirname, (error, result) ->
    # This callback is called when the upload is complete (or on error).
    $("#show_upload_progress_id").modal("hide")
    if error?
      alert("There was an error uploading the file")
      # FIXME: do something on error
      console.log("ERROR", error)
      return

    doc =
      name: upload_files[0].name
      lastModifiedDate: upload_files[0].lastModifiedDate
      type: "images"
      url: result.url
      secure_url: result.secure_url
      relative_url: result.relative_url

    if !result.url?
      # S3.upload (server side) can get wedged into a situation where
      # no error is returned but the file has not uploaded.
      console.log "NOT inserting",doc
      alert("There was an unanticipated error uploading the file.")
      # FIXME: do something on error
      console.log("ERROR", error)
      return

    # Need to get _id of newly inserted image document to put into
    # original referencing document.
    BinaryData.insert doc, (error, _id) ->
      # This is a callback called when our BinaryData collection is updated.

      # FIXME: be more useful. E.g. hide a "saving... popup"
      if error?
        console.log "image_insert_callback with error:", error
        return

      # get information from referencing collection
      data = info.body_template_data
      if data.collection? and data.my_id?
        coll = window.get_collection_from_name(data.collection) # e.g. DriverLines
        orig = coll.findOne(_id: data.my_id) # get the document to which this image is being added
        myarr = []
        myarr = orig[data.field_name]  if orig.hasOwnProperty(data.field_name)
        myarr.push _id # append our new _id
        t2 = {}
        t2[data.field_name] = myarr
        coll.update data["my_id"],
          $set: t2
      template.find("#insert_image_form").reset() # remove filename
      return

    return
  $("#file_form_div").hide()
  return {}

Template.AddImageCode2.events
  "click .edit-images": (event,template) ->
    event.preventDefault()
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id:@my_id})
    if doc? and doc.images?
      current_images = doc.images
    else
      current_images = []

    Session.set "modal_info",
      title: "Link existing image or volume"
      body_template_name: "LinkExistingImageDialog"
      body_template_data:
        my_id: @my_id
        collection_name: @collection
        current_images: current_images
      is_save_modal: true

    window.modal_save_func = link_image_save_func
    window.modal_shown_callback = on_link_image_dialog_shown
    $("#show_dialog_id").modal "show"
    return

Template.add_image_code.events
  "click .insert": (e, template) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Insert image or volume"
      body_template_name: "insert_image_dialog"
      body_template_data:
        my_id: @my_id
        collection: @collection
        field_name: "images"
      is_save_modal: true

    window.modal_save_func = insert_image_save_func
    $("#file_form_div").show()
    $("#show_dialog_id").modal "show"
    return

Template.binary_data_table.rendered = ->
  $('.flex-images').flexImages({rowHeight: 200});
  template = Template.instance()
  update_selected(template)
  return

Template.binary_data_table.helpers
  selectable_class: ->
    if Template.parentData(2).selectable_not_clickable
      return "selectable"
    else
      return

  get_n_selected: ->
    dt = Session.get "trigger_update"

    template = Template.instance()
    if !template.firstNode?
      # The DOM hasn't been rendered yet, can't count selected.
      return "? images"
    update_selected(template) # update template.n_selected if needed
    N = template.n_selected.get()
    if N==1
      return "1 image"
    else
      return N+" images"

update_selected = (template) ->
  elements = template.findAll(".selected")
  N = elements.length
  template.n_selected.set(N)

Template.binary_data_table.events
  "click .selectable": (event, template) ->
    $this = $(event.currentTarget)
    $this.toggleClass('selected')
    update_selected(template)

Template.binary_data_table.created = ->
  this.n_selected = new ReactiveVar()
  this.n_selected.set(0)

on_link_image_dialog_shown = (info, template, event) ->
  $('.flex-images').flexImages({rowHeight: 200})

  $('.selectable').removeClass('selected')
  for image_id in info.body_template_data.current_images
    $('.selectable#'+image_id).addClass('selected')

  Session.set "trigger_update",Date.now() # force update (how else to do this?)

Template.LinkExistingImageDialog.helpers
  friendly_item_name: ->
    coll = window.get_collection_from_name(@collection_name)
    my_doc = coll.findOne({_id:@my_id})
    if my_doc?
      return my_doc.name
    else
      return "<unknown>"
