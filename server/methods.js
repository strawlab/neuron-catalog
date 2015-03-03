Meteor.methods({
  verify_S3_configuration: function () {
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
