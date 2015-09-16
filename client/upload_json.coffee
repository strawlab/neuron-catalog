window.json_upload_template = null

ensure_latest_schema = ( payload_raw ) ->
  payload = {}
  file_version = payload_raw.collections.SettingsToClient.settings.SchemaVersion
  this_version = SettingsToClient.findOne({_id:'settings'}).SchemaVersion
  if this_version != file_version
    throw ('This neuron-catalog .json file was saved with a different '+
           'schema. Converting between schemas is not implemented')
  payload = payload_raw.collections

@do_upload = (payload) ->
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

Template.UploadDataDialog.destroyed = ->
  window.json_upload_template = null

Template.UploadDataDialog.created = ->
  window.json_upload_template = this
  @selected_files_var = new ReactiveVar()
  @selected_files_var.set([])

  @json_payload_var = new ReactiveVar()

  @json_upload_ready = new ReactiveVar()
  @json_upload_ready.set( false )

Template.UploadDataDialog.helpers
  selected_files: ->
    template = Template.instance()
    result = template.selected_files_var.get()
    result2 = (file for file in result) # convert from FileList to array
    return result2

Template.UploadDataDialog.events
  "click #fileSelect": (event, template) ->
    file_dom_element = template.find("#upload-data")
    if file_dom_element
      file_dom_element.click()
    event.preventDefault()

  "change #upload-data": (event, template) ->
    # The file selection changed
    template.json_upload_ready.set( false )

    file_dom_element = template.find("#upload-data")
    if !file_dom_element
      return
    template.selected_files_var.set(file_dom_element.files)
    handle_json_files(file_dom_element.files,template)

  "dragenter #upload-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "dragover #upload-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
  "drop #upload-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
     dt = event.originalEvent.dataTransfer
     template.selected_files_var.set(dt.files)
     handle_json_files(dt.files, template)

handle_json_files = (fileList, template) ->
  # template is template instance of InsertImageDialog
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
        payload = ensure_latest_schema( payload_raw )
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
