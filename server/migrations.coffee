Migrations.add
  version: 1
  name: 'Rename field "last_edit_userId" -> "last_edit_user"'
  up: ->
    for coll in [DriverLines, NeuronTypes, BrainRegions, BinaryData]
      coll.find().forEach (doc) ->
        coll.update
          _id: doc._id
        ,
          $set:
            last_edit_user: doc.last_edit_userId

          $unset:
            last_edit_userId: 1
        ,
          validate: false
          getAutoValues: false

Migrations.add
  version: 2
  name: 'Rename collection from neuropils to brain_regions'
  up: ->
    OLDNPILS = new Meteor.Collection("neuropils")

    OLDNPILS.find().forEach (doc) ->
      BrainRegions.insert(doc,{validate: false, getAutoValues: false})
      OLDNPILS.remove({_id:doc._id})

Migrations.add
  version: 3
  name: 'Rename field from neuropils to brain_regions'
  up: ->
    for coll in [DriverLines, NeuronTypes]
      coll.find().forEach (doc) ->
        coll.update
          _id: doc._id
        ,
          $set:
            brain_regions: doc.neuropils

          $unset:
            neuropils: 1
        ,
          validate: false
          getAutoValues: false

Migrations.add
  version: 4
  name: 'Store S3 bucket name, region, key separately'
  up: ->
    BinaryData.find().forEach (doc) ->
      parsed = parse_s3_url( doc.secure_url )
      BinaryData.update
        _id: doc._id
      ,
        $set:
          s3_region: parsed.s3_region
          s3_bucket: parsed.s3_bucket
          s3_key: parsed.s3_key
          s3_upload_done: true

        $unset:
          secure_url: 1
      ,
        validate: false
        getAutoValues: false

Migrations.add
  version: 5
  name: 'NeuronCatalogConfig has fixed _id'
  up: ->
    n_docs = NeuronCatalogConfig.find().count()
    if n_docs==0
      return
    if n_docs>1
      throw Error("more than one config document")
    doc = NeuronCatalogConfig.findOne()
    if doc._id=="config"
      return
    orig_id = doc._id
    doc._id = "config"
    NeuronCatalogConfig.insert(doc)
    NeuronCatalogConfig.remove({_id:orig_id})

Migrations.add
  version: 6
  name: 'Store S3 key for binary_data cache and thumbs'
  up: ->
    BinaryData.find().forEach (doc) ->
      if doc.cache_src?
        parsed = parse_s3_url( doc.cache_src )
        BinaryData.update
          _id: doc._id
        ,
          $set:
            cache_s3_key: parsed.s3_key

          $unset:
            cache_src: 1
        ,
          validate: false
          getAutoValues: false

      if doc.thumb_src?
        parsed = parse_s3_url( doc.thumb_src )
        BinaryData.update
          _id: doc._id
        ,
          $set:
            thumb_s3_key: parsed.s3_key

          $unset:
            thumb_src: 1
        ,
          validate: false
          getAutoValues: false

Migrations.migrateTo(6)
