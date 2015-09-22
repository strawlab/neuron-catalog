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
          upload_ready = body_template.zip_upload_ready.get()
          do_upload_button = parent_template.$('#modal-dialog-save')
          if upload_ready
            do_upload_button.removeClass('disabled')
          else
            do_upload_button.addClass('disabled')

        parent_template.$("#modal-dialog-save").on("click", (event) ->
          template = window.upload_template
          if template.zip_upload_ready.get()
            fileList = template.selected_zip_files_var.get()
            chosen_file = fileList[0]
            do_upload_zip_file(chosen_file)
        )

    Blaze.renderWithData( Template.ModalDialog, full_data, document.body)

  "click #download-zip": (event, template) ->
    # We want to let the default event fire (to initiate the
    # download). Here, we just close the download window.
    $("#ModalDialog").modal('hide')


get_zip_fname = () ->
  fname_base = get_fname_base()
  filename = "neuron-catalog-data_"+fname_base+".zip"

Template.DataImportExportLauncher.helpers
  zip_filename: ->
    get_zip_fname()
  zip_filename_str: ->
    fname = get_zip_fname()
    'filename='+fname
