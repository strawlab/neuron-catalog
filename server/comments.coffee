get_collection_from_name = (name) ->
  coll = undefined
  if name is "DriverLines"
    coll = DriverLines
  else if name is "NeuronTypes"
    coll = NeuronTypes
  else if name is "BrainRegions"
    coll = BrainRegions
  else coll = BinaryData  if name is "BinaryData"
  coll

# server-side helper for client/comments.coffee
Meteor.methods delete_comment: (cfg) ->
  coll = get_collection_from_name(cfg.collection_name)
  now = Date.now()
  update_doc =
    $pull:
      comments: cfg.comment
    $set:
      last_edit_user: @userId
      last_edit_time: now
  coll.update
    _id: cfg._id
  ,
    update_doc, {validate:false, getAutoValues: false}
