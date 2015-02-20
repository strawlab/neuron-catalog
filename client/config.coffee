AWSConfigTestResult = new ReactiveVar(null)
AWSConfigTestDone = new ReactiveVar(null)

on_verify_callback = (error, failures) ->
  AWSConfigTestDone.set(100)
  if error?
    console.error "Failure during remote call:",error

  if failures.length==0
    AWSConfigTestResult.set({has_error: false, msg: "AWS is correctly configured."})
  else
    AWSConfigTestResult.set({has_error: true, msg: "AWS not correctly configured.", failures:failures})

update_callback = (error, result) ->
  console.log "update complete"
  if error?
    console.error "update error:",error
  console.log "update result:",result

check_doc = (doc) ->
  coll = window.get_collection_from_name(@name)
  my_context = coll.simpleSchema().namedContext()
  my_context.validate(doc)
  invalid_keys = my_context.invalidKeys()
  if invalid_keys.length > 0
    console.log "for doc",doc
    console.warn "invalid keys",invalid_keys
    if @do_repair
      modified = false
      setter = {}
      for el in invalid_keys
        if el.type=="required"
          if el.value==null
            if el.name == "tags"
              setter[el.name] = []
              modified = true
            if el.name == "comments"
              setter[el.name] = []
              modified = true
            if el.name == "images"
              setter[el.name] = []
              modified = true
            if el.name == "synonyms"
              setter[el.name] = []
              modified = true
            if el.name == "flycircuit_idids"
              setter[el.name] = []
              modified = true
      if modified
        modifier = {}
        if setter?
          modifier["$set"]=setter
        console.log "calling update on ", @name, doc._id ,"with",modifier
        coll.update({_id: doc._id},modifier,update_callback)
  return

Template.ConfigAWSTestDialog.helpers
  result: ->
    AWSConfigTestResult.get()
  percent_done: ->
    AWSConfigTestDone.get()
  is_active: ->
    if AWSConfigTestDone.get() < 100 then "active" else ""

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

Template.config.events
  "click .download-all-data": (event, template) ->
     now = new Date()
     nowstr = now.toISOString()
     fname_base = nowstr.replace('T', '_').replace(/\:/g, '-').replace(/\..+/, '')
     link = document.createElement("a")
     link.download = "neuron-catalog-data_"+fname_base+".json"
     link.href = get_data_uri()
     link.click()

  "click .verify-aws": (event, template) ->
    AWSConfigTestResult.set(null)
    AWSConfigTestDone.set(0)
    bootbox.dialog message: window.renderTmp(Template.ConfigAWSTestDialog)
    Meteor.call("verify_AWS_configuration", on_verify_callback)
    Meteor.setTimeout(->
      if AWSConfigTestDone.get() < 100
        AWSConfigTestDone.set(30)
    ,
      300)

  "click .validate-docs": (event,template) ->
    button = event.currentTarget
    name = button.dataset.collection.valueOf()
    do_repair = Boolean(parseInt(button.dataset.repair.valueOf(),10))
    coll = window.get_collection_from_name(name)
    coll.find().forEach check_doc,
      name: name
      do_repair: do_repair
    console.log "all", name, "documents checked"
    return

Template.config.helpers
  collection_names: ->
    ["DriverLines","NeuronTypes","BrainRegions","BinaryData"]

  config_doc: ->
    NeuronCatalogConfig.findOne({})

  current_user_id: ->
    Meteor.userId()

AutoForm.hooks configQuickForm:
  onSuccess: (operation, result, template) ->
    bootbox.alert("Saved configuration successfully.")
  onError: (operation, error, template) ->
    console.error("error saving new configuration")
    bootbox.alert("Error saving configuration.")
