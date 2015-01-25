Migrations.add
  version: 1
  name: 'Rename field "last_edit_userId" -> "last_edit_user"'
  up: ->
    for coll in [DriverLines, NeuronTypes, Neuropils, BinaryData]
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

Migrations.migrateTo(1)
