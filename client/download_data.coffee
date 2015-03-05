get_data_uri = () ->
  collections = {}
  for collection_name in ["NeuronCatalogConfig","DriverLines","NeuronTypes","BrainRegions","BinaryData","Meteor.users","SettingsToClient"]
    coll = window.get_collection_from_name( collection_name )
    this_coll = {}
    coll.find().forEach (doc) ->
      this_coll[doc._id]= doc
    collections[collection_name]=this_coll
  all_data = {collections: collections, 'export_date': new Date().toISOString()}
  raw_json = JSON.stringify(all_data)
  encodedData = window.btoa(raw_json)
  result = "data:application/octet-stream;base64,"+encodedData
  return result

Template.DataImportExportLauncher.events
  "click .launch-data-import-dialog": (event, template) ->
    event.preventDefault()
    full_data =
      title: "Upload data"
      body_template: Template.UploadDataDialog
      body_data: null
      save_label: "Upload"
      render_complete: (parent_template) ->
        body_template = window.json_upload_template

        Tracker.autorun ->
          upload_ready = body_template.json_upload_ready.get()
          jq_button = parent_template.$('#modal-dialog-save')
          template = window.json_upload_template
          if upload_ready
            jq_button.removeClass('disabled')
          else
            jq_button.addClass('disabled')

        parent_template.$("#modal-dialog-save").on("click", (event) ->
          template = window.json_upload_template
          payload = template.json_payload_var.get()
          do_upload(payload)
        )

    window.add_json_view = Blaze.renderWithData(Template.ModalDialog,
      full_data, document.body)

  "click .launch-download-dialog": (event, template) ->
    # Need to launch dialog because Firefox doesn't allow link.click() in Javascript
    now = new Date()
    nowstr = now.toISOString()
    fname_base = nowstr.replace('T', '_').replace(/\:/g, '-').replace(/\..+/, '')
    filename = "neuron-catalog-data_"+fname_base+".json"
    data_url = get_data_uri()
    full_data =
      title: "Download all data"
      body_template: Template.AllDataButton
      body_data:
        data_url: data_url
        filename: filename
      hide_buttons: true

    window.download_dialog_view = Blaze.renderWithData(Template.ModalDialog,
        full_data, document.body)

Template.AllDataButton.events
  "click .download-all-data": (event, template) ->
    # We want to let the default event fire (to initiate the
    # download). Here, we just close the download window.
    Blaze.remove(window.download_dialog_view)
