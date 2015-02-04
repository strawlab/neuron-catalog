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

function get_slingshot_AWS_failures() {
  failures = [];
  if (Meteor.settings.AWSAccessKeyId) {
  } else {
    failures.push('No AWS credentials in Meteor.settings');
    return failures;
  }

  // Get AWS credentials from Meteor.settings
  AWS.config.update({accessKeyId: Meteor.settings.AWSAccessKeyId,
		     secretAccessKey: Meteor.settings.AWSSecretAccessKey});
  var params = {Bucket: Meteor.settings.S3Bucket};

  var s3 = new AWS.S3();

  // Verify that bucket name has no dots ("."). This causes Amazon's
  // wildcard HTTPS certificate for "*.s3.amazonaws.com" to fail.
  if (Meteor.settings.S3Bucket.indexOf(".") != -1) {
    failures.push('There are dots (".") in your bucket name "'+Meteor.settings.S3Bucket+'"')
  }

  // verify that bucket is in US Standard region
  try {
    var location = s3.getBucketLocationSync( params );
  } catch (ex) {
    if (ex.name == "SignatureDoesNotMatch") {
      failures.push('Signature does not match. Are your AWSAccessKeyId and AWSSecretAccessKey settings correct?');
      // Give up on finding more failures.
      return failures;
    }
    throw ex;
  }

  if (location.LocationConstraint) {
    if (location.LocationConstraint!="") {
      failures.push('Your bucket is not located in the US Standard region, but rather in "'+
		    location.LocationConstraint+'"');
    }
  }

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

Meteor.methods({
  verify_AWS_configuration: function () {
    var failures = get_slingshot_AWS_failures();
    return failures;
  },
  get_specializations: function () {
    var x = Meteor.settings.NeuronCatalogSpecializations;
    if (typeof x !== "undefined" && x !== null) {
      return x;
    } else {
      return [];
    }
  },
  remove_from_s3: function(doc) {
    console.log("FIXME: delete from S3:", doc.s3_region, doc.s3_bucket, doc.s3_key );
  }
});
