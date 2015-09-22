window.upload_template = null
Session.setDefault 'OngoingUploadFilesZip',{}

@do_upload_zip_file = (chosen_file) ->
  if chosen_file.type!="application/zip"
    console.error 'chosen_file.type is not "application/zip", proceeding anyway'

  # We stream the entire zip to the server. Alternatively, we could have opened
  # it and uploaded each file individually.

  newFile = new FS.File(chosen_file)
  newFile.once 'uploaded', ->
    tmp = Session.get "OngoingUploadFilesZip"
    delete tmp[newFile._id]
    Session.set "OngoingUploadFilesZip",tmp
    close_upload_dialog_if_no_more_uploads()
    Meteor.call("process_zip")

  bootbox.dialog
    message: window.renderTmp(Template.UploadProgress)
    title: "Upload Progress"

  # send zip file to server using CollectionFS
  ZipFileStore.insert newFile, (error, fileObj) ->
    # This is called when original insert is done (not when upload is complete).
    if error?
      console.error(error)
      bootbox.alert("There was an error uploading the file")

    tmp = Session.get("OngoingUploadFilesZip")
    tmp[fileObj._id] = true
    Session.set("OngoingUploadFilesZip", tmp)

Template.UploadDataDialog.destroyed = ->
  window.upload_template = null

Template.UploadDataDialog.created = ->
  window.upload_template = this
  @selected_zip_files_var = new ReactiveVar()
  @selected_zip_files_var.set([])

  @zip_upload_ready = new ReactiveVar()
  @zip_upload_ready.set( false )

Template.UploadDataDialog.helpers
  selected_zip_files: ->
    # convert from FileList to array
    (f for f in Template.instance().selected_zip_files_var.get())

myclick = (template,event,selector) ->
  file_dom_element = template.find(selector)
  if file_dom_element
    file_dom_element.click()
  event.preventDefault()

Template.UploadDataDialog.events
  "click #zipSelect": (event, template) ->
    myclick(template,event,"#upload-zip-data")

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
  "drop #upload-zip-data-div": (event, template) ->
     event.stopPropagation()
     event.preventDefault()
     dt = event.originalEvent.dataTransfer
     template.selected_zip_files_var.set(dt.files)
     handle_zip_files(dt.files, template)

handle_zip_files = (fileList, template) ->
  if fileList.length == 0
    return
  if fileList.length > 1
    console.error "More than one file selected"
    return
  template.zip_upload_ready.set( true )
