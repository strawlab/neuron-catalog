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

Template.DownloadData.events
  "click .download-all-data": (event, template) ->
     now = new Date()
     nowstr = now.toISOString()
     fname_base = nowstr.replace('T', '_').replace(/\:/g, '-').replace(/\..+/, '')
     link = document.createElement("a")
     link.download = "neuron-catalog-data_"+fname_base+".json"
     link.href = get_data_uri()
     link.click()
