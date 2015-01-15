options =
  allowedFileTypes: new RegExp(".*")
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
      tags: []
      comments: []
      secure_url: "(uploading)" # will be re-set later

    # Need to get _id of newly inserted image document to put into
    # S3 key.
    # No validation because @userId is null on server.
    # Also skip inserting auto values.
    _id = BinaryData.insert(doc,{validate: false, getAutoValues: false})

    "images/" + _id + "/" + doc.name

if Meteor.settings.AWSAccessKeyId
  Slingshot.createDirective "myFileUploads", Slingshot.S3Storage, options
else
  console.warn "No AWSAccessKeyId in Meteor settings. No uploads will be possible."
