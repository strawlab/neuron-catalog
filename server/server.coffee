maxSize = 0 # any size
allowedFileTypes = new RegExp(".*")

acl = "public-read"

authorize_func = (data) ->
  #Deny uploads if user is not logged in.
  unless data.userId
    message = "Please login before posting files"
    throw new Meteor.Error("Login Required", message)

  unless Roles.userIsInRole(data.userId, WriterRoles)
    message = "You are logged in, but do not have write permission"
    throw new Meteor.Error("Login Required", message)

  true

# options for primary files
options =
  allowedFileTypes: allowedFileTypes
  maxSize: maxSize
  acl: acl
  authorize: ->
     authorize_func(this)
  key: (upload_file, ctx) ->
    if Meteor.settings.AWSRegion
      region = Meteor.settings.AWSRegion
    else
      region = "us-east-1"
    doc =
      name: upload_file.name
      lastModifiedDate: ctx.lastModifiedDate
      type: "images"
      tags: []
      comments: []
      s3_region: region
      s3_bucket: Meteor.settings.S3Bucket
      s3_upload_done: false

    # Need to get _id of newly inserted image document to put into
    # S3 key.
    # No validation because @userId is null on server.
    # Also skip inserting auto values.
    _id = BinaryData.insert(doc,{validate: false, getAutoValues: false})

    # Now that we know our _id, update our document
    s3_key = "images/" + _id + "/" + upload_file.name
    updater_doc =
      $set:
        s3_key: s3_key
    BinaryData.update({_id:_id}, updater_doc,{validate: false, getAutoValues: false})
    s3_key

# options for cache and other subsidary files
options_cache =
  allowedFileTypes: allowedFileTypes
  maxSize: maxSize
  acl: acl
  authorize: ->
     authorize_func(this)
  key: (upload_file, ctx) ->
    ctx.s3_key

if Meteor.settings.AWSAccessKeyId
  Slingshot.createDirective "myFileUploads",  Slingshot.S3Storage, options
  Slingshot.createDirective "myCacheUploads", Slingshot.S3Storage, options_cache
else
  console.warn "No AWSAccessKeyId in Meteor settings. No uploads will be possible."
