get_data_uri = () ->
  collections = []
  for collection_name in ["NeuronCatalogConfig","DriverLines","NeuronTypes","BrainRegions","BinaryData","Meteor.users"]
    this_coll = {name: collection_name, documents: []}
    coll = window.get_collection_from_name( collection_name )
    coll.find().forEach (doc) ->
      this_coll.documents.push doc
    collections.push this_coll
  all_data = {collections: collections, 'export_date': new Date().toISOString()}
  raw_json = JSON.stringify(all_data)
  encodedData = window.btoa(raw_json)
  result = "data:application/octet-stream;base64,"+encodedData
  return result

Template.DownloadDataLauncher.events
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

    Blaze.renderWithData(Template.ModalDialog,
        full_data, document.body)
