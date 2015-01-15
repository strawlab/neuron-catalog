on_verify_callback = (error, failures) ->
  if error?
    console.error "Failure during remote call:",error
  if failures.length==0
    alert("AWS appears configured properly")
  else
    alert("AWS not properly configured: "+failures)
  $('.verify-aws').prop('disabled', false)

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
              setter.tags = []
              modified = true
            if el.name == "comments"
              setter.comments = []
              modified = true
            if el.name == "images"
              setter.images = []
              modified = true
            if el.name == "synonyms"
              setter.synonyms = []
              modified = true
            if el.name == "flycircuit_idids"
              setter.flycircuit_idids = []
              modified = true
      if modified
        coll.update({_id: doc._id},{$set: setter})
        console.log "called update with",setter
  return

Template.config.events
  "click .verify-aws": (e) ->
    $('.verify-aws').prop('disabled', true)
    Meteor.call("verify_AWS_configuration", on_verify_callback)
    return

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
