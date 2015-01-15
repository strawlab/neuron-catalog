on_verify_callback = (error, failures) ->
  if error?
    console.error "Failure during remote call:",error
  if failures.length==0
    alert("AWS appears configured properly")
  else
    alert("AWS not properly configured: "+failures)
  $('.verify-aws').prop('disabled', false)

check_doc = (doc) ->
  name = @valueOf()
  coll = window.get_collection_from_name(name)
  my_context = coll.simpleSchema().namedContext()
  my_context.validate(doc)
  invalid_keys = my_context.invalidKeys()
  if invalid_keys.length > 0
    conslog.log "for doc",doc
    console.warn "invalid keys",invalid_keys
  return

Template.config.events
  "click .verify-aws": (e) ->
    $('.verify-aws').prop('disabled', true)
    Meteor.call("verify_AWS_configuration", on_verify_callback)
    return

  "click .validate-docs": (event,template) ->
    button = event.currentTarget
    name = button.dataset.collection
    coll = window.get_collection_from_name(name)
    coll.find().forEach check_doc, name
    console.log "all", name, "documents checked"
    return

Template.config.helpers
  collection_names: ->
    ["DriverLines","NeuronTypes","Neuropils","BinaryData"]
