#////////////////////////////////////////////////////
@AdminConfig = new Meteor.Collection("admin_config")

if AdminConfig.find().count() is 0
  doc =
    s3_key: "yourkey"
    s3_secret: "yoursecret"
    s3_bucket: "yourbucket"
  AdminConfig.insert doc

cfg = AdminConfig.findOne()

options =
  bucket: cfg['s3_bucket']
  AWSAccessKeyId: cfg['s3_key']
  AWSSecretAccessKey: cfg['s3_secret']
  allowedFileTypes: null # all file types
  maxSize: 0 # any size
  acl: "public-read"
  authorize: ->
    #Deny uploads if user is not logged in.
    unless @userId
      message = "Please login before posting files"
      throw new Meteor.Error("Login Required", message)
    true
  key: (file) ->
    "images/"+file.name

Slingshot.createDirective "myFileUploads", Slingshot.S3Storage, options
