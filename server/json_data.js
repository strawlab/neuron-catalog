import { get_collection_from_name } from '../lib/export_data'

export function do_json_inserts (payload) {
  let results = {
    errors: [],
    numInsertedDocs: 0,
    numSkippedDocs: 0
  }

  for (let collection_name in payload) {
    if (__in__(collection_name, ['SettingsToClient', 'Meteor.users', 'NeuronCatalogConfig'])) {
      continue
    }
    let raw_data = payload[collection_name]

    let coll = get_collection_from_name(collection_name)
    for (let _id in raw_data) {
      let raw_doc = raw_data[_id]
      let current_doc = coll.findOne({_id})
      if (current_doc != null) { // if we already have this key, do not update it
        console.log(`not inserting in collection ${collection_name} doc with key ${_id}: we already have that key`)
        results.numSkippedDocs += 1
        continue
      }

      // Insert and validate but do not change timestamps, usernames.
      coll.insert(raw_doc, {getAutoValues: false}, function (error, result) {
        if (error != null) {
          results.errors.push([collection_name, raw_doc._id, error.invalidKeys])
          console.error(`for collection "${collection_name}", _id "${_id}": `, error)
          return console.error('  raw doc:', raw_doc)
        } else {
          results.numInsertedDocs += 1
          return results.numInsertedDocs
        }
      }
      )
    }
  }
  return results
}

function __in__ (needle, haystack) {
  return haystack.indexOf(needle) >= 0
}
