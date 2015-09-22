trigger_update = new Deps.Dependency

# global
window.image_upload_template = null

DEFAULT_THUMB_WIDTH = 200
DEFAULT_THUMB_HEIGHT = 200

# ---- Template.binary_data_from_id_block -------------

enhance_image_doc = (doc) ->
  if not doc?
    return

  if doc.fileObjNoTif?
    # already performed this check
    return doc

  if doc.cacheId?
    doc.fileObjNoTif = get_fileObj(doc, "cache")
  else
    doc.fileObjNoTif = get_fileObj(doc, "archive")

  if doc.thumbId?
    doc.has_thumb = true
    doc.fileObjThumb = get_fileObj(doc, "thumb")
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
  fileObjArchive: ->
    get_fileObj(this, "archive")

# -------------------------------------------------------

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

insert_image_save_func = (template, coll_name, my_id, field_name) ->
  payload = template.payload_var.get()
  if !payload?
    return

  upload_file = payload.original_file
  if !upload_file?
    return

  fileObjArchive = ArchiveFileStore.insert upload_file, (error, fileObj) ->
    # This is called when original insert is done (not when upload is complete).

    if error?
      console.error(error)
      bootbox.alert("There was an error uploading the file")
      return

    newBinaryDataDoc =
      archiveId: fileObj._id
      name: upload_file.name
      lastModifiedDate: upload_file.lastModifiedDate
      type: "images"
      tags: []
      comments: []
    BinaryData.insert newBinaryDataDoc, (error, newBinaryDataDocId) ->
      if error?
        console.error(error)
        bootbox.alert("There was an error saving upload results")
        return

      # get information from referencing collection
      if coll_name?
        coll = window.get_collection_from_name(coll_name) # e.g. DriverLines
        orig = coll.findOne(_id: my_id) # get the document to which this image is being added
        myarr = []
        myarr = orig[field_name]  if orig.hasOwnProperty(field_name)
        myarr.push newBinaryDataDocId # append our new _id
        t2 = {}
        t2[field_name] = myarr
        coll.update my_id,
          $set: t2

      if payload.full_image?
        CacheFileStore.insert payload.full_image.file, (error, fullCacheFileObj) ->
          # This is called when original insert is done (not when upload is complete).
          if error
            console.error "full cache image upload error", error
            return

          updater_doc =
            $set:
              cacheId: fullCacheFileObj._id
              cache_width: payload.full_image.width
              cache_height: payload.full_image.height
          BinaryData.update newBinaryDataDocId, updater_doc

      if payload.thumb?
        CacheFileStore.insert payload.thumb.file, (error, thumbFileObj) ->
          # This is called when original insert is done (not when upload is complete).
          if error
            console.error "thumb upload error",error
            return
          updater_doc =
            $set:
              thumbId: thumbFileObj._id
              thumb_width: payload.thumb.width
              thumb_height: payload.thumb.height
          BinaryData.update newBinaryDataDocId, updater_doc

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
    full_data =
      title: "Insert image or volume"
      body_template: Template.InsertImageDialog
      body_data: null
      save_label: "Upload"
      render_complete: (parent_template) ->
        body_template = window.image_upload_template

        Tracker.autorun ->
          upload_ready = body_template.upload_ready.get()
          jq_button = parent_template.$('#modal-dialog-save')
          if upload_ready
            jq_button.removeClass('disabled')
          else
            jq_button.addClass('disabled')

        parent_template.$("#modal-dialog-save").on("click", (event) ->
          template = window.image_upload_template
          if !template?
            return
          insert_image_save_func(template,
               send_coll, my_id, "images")
        )

    Blaze.renderWithData( Template.ModalDialog, full_data, document.body)

getThumbnail = (original, width, height) ->
  # Modified from http://stackoverflow.com/a/7557690/1633026
  canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  canvas.getContext('2d').drawImage original, 0, 0, canvas.width, canvas.height
  canvas

get_blob = ( canvas, type, quality ) ->
  binStr = atob( canvas.toDataURL(type, quality).split(',')[1] )
  len = binStr.length
  arr = new Uint8Array(len)

  i = 0
  while i < len
    arr[i] = binStr.charCodeAt(i)
    i++

  result = new Blob( [arr], {type: type || 'image/png'} )
  return result

removeExtension = (filename) ->
  lastDotPosition = filename.lastIndexOf('.')
  if lastDotPosition == -1
    filename
  else
    filename.substr 0, lastDotPosition

handle_file_step_two = ( chosen_file, template, opts ) ->
  opts = opts || {}

  payload = {}
  payload.original_file = chosen_file
  if opts.full_image?

    shortname = removeExtension(chosen_file.name)
    if opts.preserve_full_image
      canvas = document.createElement('canvas')
      canvas.width = opts.full_image.width
      canvas.height = opts.full_image.height

      ctx = canvas.getContext('2d')
      ctx.drawImage(opts.full_image, 0, 0, canvas.width, canvas.height)
      blob = get_blob( canvas, "image/jpeg", 0.8)
      fname = shortname + '.jpg'
      file = new File([blob],fname)
      payload.full_image =
        file: file
        width: canvas.width
        height: canvas.height

    max_width = DEFAULT_THUMB_WIDTH
    max_height = DEFAULT_THUMB_HEIGHT

    orig_aspect = opts.full_image.width/opts.full_image.height
    target_aspect = max_width/max_height
    if orig_aspect >= target_aspect
      # image aspect is wider (or equal) than bounding box
      actual_width = max_width
      scale = max_width/opts.full_image.width
      actual_height = Math.floor(opts.full_image.height*scale)
    else
      # image aspect is taller than bounding box
      actual_height = max_height
      scale = max_height/opts.full_image.height
      actual_width = Math.floor(opts.full_image.width*scale)

    thumb_canvas = getThumbnail(opts.full_image, actual_width, actual_height)
    blob = get_blob( thumb_canvas, "image/jpeg", 0.8)
    fname = 'thumb-' + shortname + '.jpg'
    file = new File([blob],fname)

    payload.thumb =
      file: file
      width: actual_width
      height: actual_height

    div = template.find("#preview")
    $(div).empty()
    div.appendChild(thumb_canvas)
  template.payload_var.set( payload )
  template.upload_ready.set( true )

handle_files = (fileList, template) ->
  # template is template instance of InsertImageDialog
  if fileList.length == 0
    return
  if fileList.length > 1
    console.error "More than one file selected"
    return
  chosen_file = fileList[0]
  if chosen_file.type == "image/tiff"
    tiff_reader = new FileReader()
    tiff_reader.onload = ((theFile) ->
      (e) ->
        try
          Tiff.initialize({TOTAL_MEMORY: theFile.size*4})
          tiff = new Tiff(buffer: e.target.result)
        catch exception

          full_data =
            title: "Error processing TIFF file"
            body_template: Template.TiffError
            body_data: null
            hide_buttons: true

          $("#ModalDialog").modal('hide')
          Blaze.renderWithData(Template.ModalDialog,
            full_data, document.body)

          throw exception
        dataUrl = tiff.toDataURL()
        img = document.createElement('img')
        img.onload = ->
          handle_file_step_two( chosen_file, template, {full_image: img, preserve_full_image: true} )
        img.src = dataUrl
        return
    )(chosen_file)

    tiff_reader.readAsArrayBuffer(chosen_file)
    # use libtiff to convert to a Tiff instance
    #tiff = new Tiff(buffer: buffer)
  else
    imageType = /^image\//
    if imageType.test(chosen_file.type)
      img = document.createElement("img")
      img.onload = ->
        handle_file_step_two( chosen_file, template, {full_image: img} )
      img.file = chosen_file
      img_reader = new FileReader
      img_reader.onload = ((aImg) ->
        (e) ->
          aImg.src = e.target.result
          return
      )(img)
      img_reader.readAsDataURL chosen_file

    else
      handle_file_step_two( chosen_file, template )

Template.InsertImageDialog.destroyed = ->
  window.image_upload_template = null

Template.InsertImageDialog.created = ->
  window.image_upload_template = this

  @selected_files = new ReactiveVar()
  @selected_files.set([])

  @payload_var = new ReactiveVar()

  @upload_ready = new ReactiveVar()
  @upload_ready.set( false )

  # prevent dropping files onto page creating navigation
  # http://stackoverflow.com/a/6756680/1633026
  window.addEventListener 'dragover', ((e) ->
    e = e or event
    e.preventDefault()
    return
  ), false
  window.addEventListener 'drop', ((e) ->
    e = e or event
    e.preventDefault()
    return
  ), false

Template.InsertImageDialog.helpers
  selected_files: ->
    template = Template.instance()
    result = template.selected_files.get()
    result2 = (file for file in result) # convert from FileList to array
    return result2

Template.InsertImageDialog.events
  # consider also implementing a paste event
  # e.g. http://jsfiddle.net/KJW4E/222/
  "change #insert_image": (event, template) ->
    # The file selection changed
    template.upload_ready.set( false )

    div = template.find("#preview")
    $(div).empty()
    append_spinner(div)

    file_dom_element = template.find("#insert_image")
    if !file_dom_element
      return
    template.selected_files.set(file_dom_element.files)
    handle_files(file_dom_element.files,template)

  "click #fileSelect": (event, template) ->
    file_dom_element = template.find("#insert_image")
    if file_dom_element
      file_dom_element.click()
    event.preventDefault()

  "dragenter #file_form_div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "dragover #file_form_div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "drop #file_form_div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
     dt = event.originalEvent.dataTransfer
     template.selected_files.set(dt.files)
     handle_files(dt.files, template)

Template.binary_data_table.onRendered ->
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
  default_thumb_width: ->
    return DEFAULT_THUMB_WIDTH
  default_thumb_height: ->
    return DEFAULT_THUMB_HEIGHT

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
