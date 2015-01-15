on_verify_callback = (error, failures) ->
  if error?
    console.error "Failure during remote call:",error
  if failures.length==0
    alert("AWS appears configured properly")
  else
    alert("AWS not properly configured: "+failures)
  $('.verify-aws').prop('disabled', false)

Template.config.events
  "click .verify-aws": (e) ->
    $('.verify-aws').prop('disabled', true)
    Meteor.call("verify_AWS_configuration", on_verify_callback)
    return

