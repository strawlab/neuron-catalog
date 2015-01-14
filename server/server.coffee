options =
  allowedFileTypes: null # all file types
  maxSize: 0 # any size
  acl: "public-read"
  authorize: ->
    #Deny uploads if user is not logged in.
    unless @userId
      message = "Please login before posting files"
      throw new Meteor.Error("Login Required", message)
    true
  key: (upload_file, ctx) ->
    doc =
      name: upload_file.name
      lastModifiedDate: ctx.lastModifiedDate
      type: "images"
      status: "uploading"
    # Need to get _id of newly inserted image document to put into
    # S3 key
    _id = BinaryData.insert(doc)
    "images/" + _id + "/" + doc.name

if Meteor.settings.AWSAccessKeyId
  Slingshot.createDirective "myFileUploads", Slingshot.S3Storage, options
else
  console.warn "No AWSAccessKeyId in Meteor settings. No uploads will be possible."
