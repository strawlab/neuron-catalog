Meteor.subscribe "simple_upload_processor_status"

# --------------------------------------------

Template.UploadProcessorStatus.helpers get_upload_processor_has_error: ->
  doc = SimpleUploadProcessorStatus.findOne({'_id':'status'})
  if doc?
    return !doc.status_is_ok
  return true

# --------------------------------------------

Template.MyLayout.helpers
  top_margin_class_attrs: ->
    doc = SimpleUploadProcessorStatus.findOne({'_id':'status'})
    result = 'top50'
    if doc?
      if doc.status_is_ok
        result = ''
    result
