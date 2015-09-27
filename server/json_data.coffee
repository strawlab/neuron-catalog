@do_json_inserts = (payload) ->
  results =
    errors: []
    numInsertedDocs: 0
    numSkippedDocs: 0

  for collection_name of payload
    if collection_name in ["SettingsToClient","Meteor.users","NeuronCatalogConfig"]
      continue
    raw_data = payload[collection_name]

    coll = get_collection_from_name( collection_name )
    for _id of raw_data
      raw_doc = raw_data[_id]
      current_doc = coll.findOne({_id:_id})
      if current_doc? # if we already have this key, do not update it
        console.log "not inserting in collection "+collection_name+" doc with key "+_id+": we already have that key"
        results.numSkippedDocs += 1
        continue

      # Insert and validate but do not change timestamps, usernames.
      coll.insert( raw_doc, {getAutoValues: false}, (error,result) ->
        if error?
          results.errors.push( [collection_name, raw_doc._id, error.invalidKeys] )
          console.error 'for collection "'+collection_name+'", _id "'+_id+'": ',error
          console.error '  raw doc:',raw_doc
        else
          results.numInsertedDocs += 1
        )
  return results
