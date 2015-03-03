S3ConfigTestResult = new ReactiveVar(null)
S3ConfigTestDone = new ReactiveVar(null)

on_verify_callback = (error, failures) ->
  S3ConfigTestDone.set(100)
  if error?
    bootbox.alert("Failure during remote call: "+error)
    throw error

  if failures.length==0
    S3ConfigTestResult.set({has_error: false, msg: "S3 is correctly configured."})
  else
    S3ConfigTestResult.set({has_error: true, msg: "S3 not correctly configured.", failures:failures})

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

Template.ConfigS3TestDialog.helpers
  result: ->
    S3ConfigTestResult.get()
  percent_done: ->
    S3ConfigTestDone.get()
  is_active: ->
    if S3ConfigTestDone.get() < 100 then "active" else ""

Template.config.events
  "click .verify-s3": (event, template) ->
    S3ConfigTestResult.set(null)
    S3ConfigTestDone.set(0)
    bootbox.dialog message: window.renderTmp(Template.ConfigS3TestDialog)
    Meteor.call("verify_S3_configuration", on_verify_callback)
    Meteor.setTimeout(->
      if S3ConfigTestDone.get() < 100
        S3ConfigTestDone.set(30)
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

AutoForm.hooks configQuickForm:
  onSuccess: (operation, result, template) ->
    bootbox.alert("Saved configuration successfully.")
  onError: (operation, error, template) ->
    console.error("error saving new configuration")
    bootbox.alert("Error saving configuration.")
