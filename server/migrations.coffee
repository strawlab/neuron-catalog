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

v7_get_s3_url = (region, bucket, key) ->
  if region == 'us-east-1'
    return 'https://s3.amazonaws.com/' + bucket + '/' + key
  'https://' + 's3-' + region + '.amazonaws.com/' + bucket + '/' + key

v7_get_fileObj = (doc,key) ->
  url = v7_get_s3_url(doc.s3_region, doc.s3_bucket, key)
  fileObj = new FS.File(url)
  fileObj

Migrations.add
  version: 7
  name: 'Use CollectionFS rather than S3'
  up: ->
    BinaryData.find().forEach (doc) ->

      setters = {}
      removers =
        s3_bucket: 1
        s3_region: 1
        s3_upload_done: 1

      fileObjArchive = ArchiveFileStore.insert v7_get_fileObj(doc, doc.s3_key)
      setters.archiveId = fileObjArchive._id
      removers.s3_key = 1

      if doc.thumb_s3_key
        fileObjThumb = CacheFileStore.insert v7_get_fileObj(doc, doc.thumb_s3_key)
        setters.thumbId = fileObjThumb._id
        removers.thumb_s3_key = 1

      if doc.cache_s3_key
        fileObjCache = CacheFileStore.insert v7_get_fileObj(doc, doc.cache_s3_key)
        setters.cacheId = fileObjCache._id
        removers.cache_s3_key = 1

      BinaryData.update { _id: doc._id }, {
        $set: setters
        $unset: removers
      },
        validate: false
        getAutoValues: false

Migrations.add
  version: 8
  name: 'Add .profile.name field to user docs'
  up: ->
    Meteor.users.find().forEach (doc) ->
      Meteor.users.update
        _id: doc._id
      ,
        $set:
          profile:
            name: doc.username

Migrations.add
  version: 9
  name: 'Rework permissions system'
  up: ->

    permission_map =
      'admin': ['read','write','admin']
      'read-write': ['read','write']
      'read-only': [ 'read' ]

    # Remove old roles from Meteor.roles collection
    for old_role of permission_map
      doc = Meteor.roles.findOne({name:old_role})
      if doc?
        Meteor.roles.remove({_id:doc._id})

    # Update user docs for new roles
    Meteor.users.find().forEach (doc) ->
      # use object to prevent repeated keys
      new_permissions = {}
      for old_permission in doc.roles
        for new_permission in permission_map[old_permission]
          new_permissions[new_permission] = true
      new_permissions = (new_permission for new_permission of new_permissions)

      Meteor.users.update { _id: doc._id }, $set: roles: new_permissions
