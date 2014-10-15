#////////////////////////////////////////////////////
@AdminConfig = new Meteor.Collection("admin_config")

if AdminConfig.find().count() is 0
  doc =
    s3_key: "yourkey"
    s3_secret: "yoursecret"
    s3_bucket: "yourbucket"
    s3_region: "yourregion-optional"
  AdminConfig.insert doc

cfg = AdminConfig.findOne()
S3.config =
  key    : cfg['s3_key']
  secret : cfg['s3_secret']
  bucket : cfg['s3_bucket']
  region : cfg['s3_region']
