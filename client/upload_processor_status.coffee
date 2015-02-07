Meteor.subscribe "upload_processor_status"

Session.setDefault "upload_processor_has_error", false

# --------------------------------------------
# timer functions

update_upload_processor_status = ->
  doc = UploadProcessorStatus.findOne({'_id':'status'})
  if !doc?
    Session.set("upload_processor_has_error",true)
    return

  Session.set("upload_processor_has_error",false)
  return

Meteor.setInterval(update_upload_processor_status, 5000) # check status every 5 seconds

# --------------------------------------------

Template.UploadProcessorStatus.helpers get_upload_processor_has_error: ->
  Session.get("upload_processor_has_error")

# --------------------------------------------

Template.MyLayout.helpers
  top_margin_class_attrs: ->
    if Session.get("upload_processor_has_error")
      result = 'top50'
    else
      result = ''
    result
