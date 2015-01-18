Session.setDefault "AWSConfigTestResult", null
Session.setDefault "AWSConfigTestDone", 0

on_verify_callback = (error, failures) ->
  Session.set("AWSConfigTestDone", 100)
  if error?
    console.error "Failure during remote call:",error

  if failures.length==0
    Session.set "AWSConfigTestResult", "AWS is correctly configured."
  else
    Session.set "AWSConfigTestResult", "AWS not correctly configured: "+failures

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
    Session.get "AWSConfigTestResult"
  percent_done: ->
    Session.get("AWSConfigTestDone")
  is_active: ->
    if Session.get("AWSConfigTestDone") < 100 then "active" else ""

Template.config.events
  "click .verify-aws": (e) ->
    Session.set "AWSConfigTestResult", null
    Session.set("AWSConfigTestDone",0)
    bootbox.dialog message: window.renderTmp(Template.ConfigAWSTestDialog)
    Meteor.call("verify_AWS_configuration", on_verify_callback)
    window.setTimeout(->
      Session.set("AWSConfigTestDone",30)
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
    ["DriverLines","NeuronTypes","Neuropils","BinaryData"]

  config_doc: ->
    NeuronCatalogConfig.findOne({})

  current_user_id: ->
    Meteor.userId()
