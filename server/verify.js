var AWS = Meteor.npmRequire('aws-sdk');

// Get AWS credentials from Meteor.settings
AWS.config.update({accessKeyId: Meteor.settings.AWSAccessKeyId, secretAccessKey: Meteor.settings.AWSSecretAccessKey});

// Load IAM credentials
//console.log(Meteor.settings);

var s3 = new AWS.S3();
//console.log("s3",s3);

//console.log("s3.listBucketsSync()",s3.listBuckets());

var params = {Bucket: Meteor.settings.S3Bucket};
console.log(params);
var list = s3.listObjectsSync( params );
console.log("list",list);
//var cors = s3.getBucketCorsSync( params );
//var cors = s3.GetBucketCorsSync( params );
//var cors = s3.GetBucketCors( params );

// verify that bucket is in US Standard region

// verify that bucket name has no dots

// verify bucket CORS config

// verify bucket policy

// verify we have IAM permission to upload to bucket

// optional?: verify bucket has website hosting enabled
