trigger_update = new Deps.Dependency

my_uploader = null # variable local to this script
uploader_state_changed = new Deps.Dependency
upload_progress_dialog = null

# ---- Template.binary_data_from_id_block -------------

enhance_image_doc = (doc) ->
  if not doc?
    return

  if doc.secure_url_notif?
    # already performed this check
    return doc

  if doc.cache_src?
    doc.secure_url_notif = doc.cache_src
  else
    doc.secure_url_notif = compute_secure_url(doc)

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
Template.binary_data_show.events
  "load .loadable": (event,template) ->
    Session.set "image_visible", true

# -------------------------------------------------------
Template.binary_data_show.helpers
  hack: ->
    # This is a hack to hide image before its load event is fired.
    Session.set "image_visible", false

  is_image_hidden: ->
    not Session.get "image_visible"

  binary_data_type: ->
    @type.slice(0,-1)

  find_references: ->
    coll_types = ["DriverLines","NeuronTypes","BrainRegions"]
    image_id = @_id
    query =
      images: image_id
    result = []
    for collname in coll_types
      coll = window.get_collection_from_name(collname)
      coll.find(query).forEach (doc) ->
        result.push {"collection":collname,"doc":doc,"my_id":doc._id}
    result
  secure_url: ->
    compute_secure_url(this)

# -------------------------------------------------------

# @remove_binary_data is defined in ../neuron-catalog.coffee

link_image_save_func = (template,collection_name,my_id) ->
  coll = window.get_collection_from_name(collection_name)
  elements = template.find(".selected")
  myarr = []
  for item in elements
    myarr.push(item.id)

  t2 = {images:myarr}
  coll.update my_id,
    $set: t2

# -------------

Template.UploadProgress.helpers
  percent_uploaded: ->
    uploader_state_changed.depend()
    if !my_uploader?
      return 0
    Math.round(my_uploader.progress() * 100);

get_id_from_key = (key) ->
  arr = key.split("/")
  if arr.length == 3
    if arr[0]=="images"
      _id = arr[1]
  return _id

insert_image_save_func = (template, coll_name, my_id, field_name) ->
  # FIXME: disable save/cancel button
  fb = template.find("#insert_image")[0]
  upload_files = fb.files
  # FIXME: assert size(upload_files)==1
  upload_file = upload_files[0]
  s3_dirname = "/images"

  upload_progress_dialog = bootbox.dialog
      title: "upload progress"
      message: window.renderTmp(Template.UploadProgress)

  ctx =
    lastModifiedDate: upload_file.lastModifiedDate

  my_uploader = new Slingshot.Upload("myFileUploads",ctx)
  uploader_state_changed.changed()

  my_uploader.send upload_file, (error, downloadUrl) ->
    # This callback is called when the upload is complete (or on error).
    upload_progress_dialog.modal('hide')
    upload_progress_dialog = null

    if error?
      my_uploader = null
      uploader_state_changed.changed()
      console.error(error)
      bootbox.alert("There was an error uploading the file")
      return

    s3_key = my_uploader.param('key')
    my_uploader = null
    uploader_state_changed.changed()

    _id = get_id_from_key( s3_key )
    updater_doc =
      $set:
        s3_upload_done: true
    BinaryData.update _id, updater_doc

    # get information from referencing collection
    if coll_name?
      coll = window.get_collection_from_name(coll_name) # e.g. DriverLines
      orig = coll.findOne(_id: my_id) # get the document to which this image is being added
      myarr = []
      myarr = orig[field_name]  if orig.hasOwnProperty(field_name)
      myarr.push _id # append our new _id
      t2 = {}
      t2[field_name] = myarr
      coll.update my_id,
        $set: t2
    template.find("#insert_image_form")[0].reset() # remove filename

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

    send_coll = @collection
    send_id = @my_id
    data =
      my_id: send_id
      collection_name: send_coll
      current_images: current_images
    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.LinkExistingImageDialog,data)
      title: "Link existing image or volume"
      buttons:
        close:
          label: "Close"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            link_image_save_func(dialog_template, send_coll, send_id)

    window.dialog_template.on("shown.bs.modal", ->
      on_link_image_dialog_shown(data)
    )

Template.add_image_code.events
  "click .insert": (event, template) ->
    event.preventDefault()
    send_coll = @collection
    my_id = @my_id
    data =
      field_name: "images"
      collection: send_coll
      my_id: my_id
    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.InsertImageDialog, data)
      title: "Insert image or volume"
      buttons:
        close:
          label: "Close"
        save:
          label: "Upload"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            insert_image_save_func(dialog_template, send_coll, my_id, "images")

Template.InsertImageDialog.created = ->
  @selected_files = new ReactiveVar()
  @selected_files.set([])

Template.InsertImageDialog.helpers
  selected_files: ->
    template = Template.instance()
    result = template.selected_files.get()
    result2 = (file for file in result) # convert from FileList to array
    return result2

Template.InsertImageDialog.events
  "change #insert_image": (event, template) ->
    file_dom_element = template.find("#insert_image")
    if !file_dom_element
      return
    template.selected_files.set(file_dom_element.files)

  "click #fileSelect": (event, template) ->
    file_dom_element = template.find("#insert_image")
    if file_dom_element
      file_dom_element.click()
    event.preventDefault()

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
    trigger_update.depend()
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

on_link_image_dialog_shown = (data) ->
  $('.flex-images').flexImages({rowHeight: 200})

  $('.selectable').removeClass('selected')
  for image_id in data.current_images
    $('.selectable#'+image_id).addClass('selected')

  trigger_update.changed() # force update

Template.LinkExistingImageDialog.helpers
  friendly_item_name: ->
    coll = window.get_collection_from_name(@collection_name)
    my_doc = coll.findOne({_id:@my_id})
    if my_doc?
      return my_doc.name
    else
      return "<unknown>"
