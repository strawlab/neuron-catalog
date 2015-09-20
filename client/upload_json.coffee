window.upload_template = null

ensure_latest_json_schema = ( payload_raw ) ->
  payload = {}
  file_version = payload_raw.collections.SettingsToClient.settings.SchemaVersion
  this_version = SettingsToClient.findOne({_id:'settings'}).SchemaVersion
  if this_version != file_version
    throw ('This neuron-catalog .json file was saved with a different '+
           'schema. Converting between schemas is not implemented')
  payload = payload_raw.collections

@do_json_inserts = (payload) ->
  for collection_name of payload
    if collection_name in ["SettingsToClient","Meteor.users","NeuronCatalogConfig"]
      continue
    raw_data = payload[collection_name]

    coll = window.get_collection_from_name( collection_name )
    for _id of raw_data
      raw_doc = raw_data[_id]
      current_doc = coll.findOne({_id:_id})
      if !current_doc? # if we already have this key, do not update it
        coll.insert( raw_doc, (error,result) ->
          if error?
            console.error 'for collection "'+collection_name+'", _id "'+_id+'": ',error
          )

@do_upload_zip_file = (chosen_file) ->
  if chosen_file.type!="application/zip"
    console.error 'chosen_file.type is not "application/zip", proceeding anyway'

  # We stream the entire zip to the server. Alternatively, we could have opened
  # it and uploaded each file individually.

  newFile = new FS.File(chosen_file)
  newFile.once 'uploaded', ->
    Meteor.call("process_zip")

  # send zip file to server using CollectionFS
  ZipFileStore.insert newFile, (error, fileObj) ->
    # This is called when original insert is done (not when upload is complete).
    if error?
      console.error(error)
      bootbox.alert("There was an error uploading the file")

Template.UploadDataDialog.destroyed = ->
  window.upload_template = null

Template.UploadDataDialog.created = ->
  window.upload_template = this
  @selected_json_files_var = new ReactiveVar()
  @selected_json_files_var.set([])
  @selected_zip_files_var = new ReactiveVar()
  @selected_zip_files_var.set([])

  @json_payload_var = new ReactiveVar()

  @json_upload_ready = new ReactiveVar()
  @json_upload_ready.set( false )
  @zip_upload_ready = new ReactiveVar()
  @zip_upload_ready.set( false )

Template.UploadDataDialog.helpers
  selected_json_files: ->
    # convert from FileList to array
    (f for f in Template.instance().selected_json_files_var.get())
  selected_zip_files: ->
    # convert from FileList to array
    (f for f in Template.instance().selected_zip_files_var.get())

myclick = (template,event,selector) ->
  file_dom_element = template.find(selector)
  if file_dom_element
    file_dom_element.click()
  event.preventDefault()

Template.UploadDataDialog.events
  "click #jsonSelect": (event, template) ->
    myclick(template,event,"#upload-json-data")
  "click #zipSelect": (event, template) ->
    myclick(template,event,"#upload-zip-data")

  "change #upload-json-data": (event, template) ->
    # The file selection changed
    template.json_upload_ready.set( false )
    file_dom_element = template.find("#upload-json-data")
    if !file_dom_element
      return
    template.selected_json_files_var.set(file_dom_element.files)
    handle_json_files(file_dom_element.files,template)

  "change #upload-zip-data": (event, template) ->
    # The file selection changed
    template.zip_upload_ready.set( false )
    file_dom_element = template.find("#upload-zip-data")
    if !file_dom_element
      return
    template.selected_zip_files_var.set(file_dom_element.files)
    handle_zip_files(file_dom_element.files,template)

  "dragenter .mydrag": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "dragover .mydrag": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "drop #upload-json-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
     dt = event.originalEvent.dataTransfer
     template.selected_json_files_var.set(dt.files)
     handle_json_files(dt.files, template)
  "drop #upload-zip-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
     dt = event.originalEvent.dataTransfer
     template.selected_zip_files_var.set(dt.files)
     handle_zip_files(dt.files, template)

handle_json_files = (fileList, template) ->
  if fileList.length == 0
    return
  if fileList.length > 1
    console.error "More than one file selected"
    return
  chosen_file = fileList[0]
  if chosen_file.type!="application/json"
    console.error 'chosen_file.type is not "application/json", proceeding anyway'

  json_reader = new FileReader()
  json_reader.onload = ((theFile) ->
    (e) ->
      try
        payload_raw = JSON.parse( e.target.result )
        payload = ensure_latest_json_schema( payload_raw )
      catch exception
        full_data =
          title: "Error processing JSON file"
          body_template: Template.JSONError
          body_data:
            error: exception.toString()
          hide_buttons: true
        $("#ModalDialog").modal('hide')
        Blaze.renderWithData(Template.ModalDialog,
          full_data, document.body)
        throw exception

      template.json_payload_var.set( payload )
      template.json_upload_ready.set( true )
  )(chosen_file)
  json_reader.readAsText(chosen_file)

handle_zip_files = (fileList, template) ->
  if fileList.length == 0
    return
  if fileList.length > 1
    console.error "More than one file selected"
    return
  template.zip_upload_ready.set( true )
