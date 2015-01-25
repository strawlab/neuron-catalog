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
  name: 'Rename collection from neuropils to brain_regions',
  up: ->
    OLDNPILS = new Meteor.Collection("neuropils")

    OLDNPILS.find().forEach (doc) ->
      BrainRegions.insert(doc,{validate: false, getAutoValues: false})
      OLDNPILS.remove({_id:doc._id})

Migrations.add
  version: 3
  name: 'Rename field from neuropils to brain_regions',
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

Migrations.migrateTo(3)
