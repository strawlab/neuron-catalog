// This modules requires global variable AWS from peerlibrary:aws-sdk

function _append_CORS_failures( cors, failures ) {
  var found_OK=false;
  for (var idx in cors.CORSRules) {
    var rule = cors.CORSRules[idx];
    if (rule.AllowedOrigins.indexOf('*')!=-1) {
      if (rule.AllowedMethods.length==4) {
	if (rule.AllowedMethods.indexOf('PUT')!=-1 & rule.AllowedMethods.indexOf('POST')!=-1 &
	    rule.AllowedMethods.indexOf('GET')!=-1 & rule.AllowedMethods.indexOf('HEAD')!=-1) {
	  found_OK=true;
	}
      }
    }
  }
  if (!found_OK) {
    failures.push("No CORS rule to allow PUT, POST, GET, HEAD from any origin.")
  }
}

get_slingshot_AWS_failures = function() {

  // We seem to be affected by a similar bug to this. This function
  // will succeed the first time but will then fail.
  // https://github.com/peerlibrary/meteor-aws-sdk/issues/12

  failures = [];
  if (Meteor.settings.AWSAccessKeyId) {
  } else {
    failures.push('No AWS credentials in Meteor.settings');
    return failures;
  }

  // Get AWS credentials from Meteor.settings
  AWS.config.update({accessKeyId: Meteor.settings.AWSAccessKeyId,
		     secretAccessKey: Meteor.settings.AWSSecretAccessKey,
		     region: Meteor.settings.AWSRegion || "us-east-1",
		    });
  var params = {Bucket: Meteor.settings.S3Bucket,
	       };

  var s3 = new AWS.S3();

  // verify bucket CORS config
  var have_cors = false;
  try {
    var cors = s3.getBucketCorsSync( params );
    have_cors = true;
  } catch(ex) {
    failures.push('Could not get CORS for bucket: '+ex.name+': '+ex.message);
  }

  if (have_cors) {
    _append_CORS_failures( cors, failures );
  }

  // verify bucket policy
  var have_policy = false;
  try {
    var policy = s3.getBucketPolicySync( params );
    have_policy = true;
  } catch (ex) {
    failures.push('Could not get policy for bucket: '+ex.name+': '+ex.message);
  }

  if (have_policy) {
    // FIXME: actually check the policy
    //console.log("policy",policy);
  }

  // FIXME: implement the rest of this stuff
  // verify we have IAM permission to upload to bucket

  // optional?: verify bucket has website hosting enabled

  return failures;
}

function publish_s3_failures() {
  var failures = get_slingshot_AWS_failures();

  if (failures.length==0) {
    is_ok = true;
  } else {
    is_ok = false;
  }
  S3ConfigStatus.update( {_id: 'status'},
			  {$set: {is_ok: is_ok}},
			  {upsert: true});
}

Meteor.startup(function() {
  publish_s3_failures(); // call once at startup

  // every 2 hours check S3 settings
  Meteor.setInterval( function() {publish_s3_failures();}, 1000*60*60*2 );
})
