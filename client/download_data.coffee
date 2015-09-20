get_data_uri = () ->
  raw_json = export_data()
  encodedData = utf8_to_b64(raw_json)
  result = "data:application/octet-stream;base64,"+encodedData
  return result

get_fname_base = () ->
  now = new Date()
  nowstr = now.toISOString()
  fname_base = nowstr.replace('T', '_').replace(/\:/g, '-').replace(/\..+/, '')

Template.DataImportExportLauncher.events
  "click .launch-data-import-dialog": (event, template) ->
    event.preventDefault()
    full_data =
      title: "Upload data"
      body_template: Template.UploadDataDialog
      body_data: null
      save_label: "Upload"
      render_complete: (parent_template) ->
        body_template = window.upload_template

        Tracker.autorun ->
          upload_ready = body_template.json_upload_ready.get() || body_template.zip_upload_ready.get()
          do_upload_button = parent_template.$('#modal-dialog-save')
          if upload_ready
            do_upload_button.removeClass('disabled')
          else
            do_upload_button.addClass('disabled')

          if body_template.zip_upload_ready.get()
            parent_template.$('.myjson').addClass('disabled')
          else
            parent_template.$('.myjson').removeClass('disabled')

          if body_template.json_upload_ready.get()
            parent_template.$('.myzip').addClass('disabled')
          else
            parent_template.$('.myzip').removeClass('disabled')

        parent_template.$("#modal-dialog-save").on("click", (event) ->
          template = window.upload_template
          if template.zip_upload_ready.get()
            fileList = template.selected_zip_files_var.get()
            chosen_file = fileList[0]
            do_upload_zip_file(chosen_file)
          if template.json_upload_ready.get()
            json_payload = template.json_payload_var.get()
            do_json_inserts(json_payload)
        )

    Blaze.renderWithData( Template.ModalDialog, full_data, document.body)

  "click .launch-download-dialog": (event, template) ->
    # Need to launch dialog because Firefox doesn't allow link.click() in Javascript
    fname_base = get_fname_base()
    filename = "neuron-catalog-data_"+fname_base+".json"
    data_url = get_data_uri()
    full_data =
      title: "Download all data"
      body_template: Template.AllDataButton
      body_data:
        data_url: data_url
        filename: filename
      hide_buttons: true

    Blaze.renderWithData( Template.ModalDialog, full_data, document.body)

Template.AllDataButton.events
  "click #download-all-data": (event, template) ->
    # We want to let the default event fire (to initiate the
    # download). Here, we just close the download window.
    $("#ModalDialog").modal('hide')
  "click #download-zip": (event, template) ->
    # We want to let the default event fire (to initiate the
    # download). Here, we just close the download window.
    $("#ModalDialog").modal('hide')


get_zip_fname = () ->
  fname_base = get_fname_base()
  filename = "neuron-catalog-data_"+fname_base+".zip"
Template.AllDataButton.helpers
  zip_filename: ->
    get_zip_fname()
  zip_filename_str: ->
    fname = get_zip_fname()
    'filename='+fname
