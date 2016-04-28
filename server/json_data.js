import { Meteor } from 'meteor/meteor'

import { SettingsToClient } from '../lib/model'
import { get_collection_from_name, convertToPlain } from '../lib/export_data'
import { implementations } from './migrationImplementation'

// As a security measure, do not set these collections.
const doNotUpdate = ['Meteor.users', 'Meteor.roles', 'SettingsToClient', 'NeuronCatalogConfig']

function ensure_latest_json_schema (collections) {
  const originalVersion = collections.SettingsToClient.settings.SchemaVersion
  let targetVersion = SettingsToClient.findOne({_id: 'settings'}).SchemaVersion

  // create an in-memory Collection of each (maybe old schema) Collection
  const newCollections = {}
  Object.keys(collections).forEach(function (collectionName) {
    if (__in__(collectionName, doNotUpdate)) {
      return
    }
    const newCollection = new Meteor.Collection(null) // create in-memory
    const data = collections[collectionName]
    Object.keys(data).forEach(function (_id) {
      const doc = data[_id]
      newCollection.insert(doc)
    })
    newCollections[collectionName] = newCollection
  })

  let dataVersion = originalVersion
  while (dataVersion !== targetVersion) {
    const nextVersion = dataVersion + 1
    const impl = implementations[nextVersion]
    const argNamesToConvert = []
    impl.argNames.forEach(function (argName) {
      if (__in__(argName, doNotUpdate)) {
        return
      }
      argNamesToConvert.push(argName)
    })

    const args = []
    argNamesToConvert.forEach(function (argName) {
      const collectionData = newCollections[argName]
      args.push(collectionData)
    })

    if (args.length > 0) {
      console.log(`Migrating data from ${dataVersion} to ${nextVersion}.`)
      impl.upFunc.apply(null, args)
    } else {
      // Probably we removed the work via doNotUpdate
      console.log(`Skipping migration from ${dataVersion} to ${nextVersion}: nothing to do.`)
    }

    dataVersion++
  }

  const result = {}
  Object.keys(newCollections).forEach(function (collName) {
    const coll = newCollections[collName]
    result[collName] = convertToPlain(coll, collName)
  })
  return result
}

export function processJsonBuf (collections) {
  const payload = ensure_latest_json_schema(collections)
  return do_json_inserts(payload)
}

export function processRawJsonBuf (buf) {
  const data = JSON.parse(buf)
  return processJsonBuf(data.collections)
}

function do_json_inserts (payload) {
  let results = {
    errors: [],
    numInsertedDocs: 0,
    numSkippedDocs: 0
  }

  for (let collection_name in payload) {
    if (__in__(collection_name, doNotUpdate)) {
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
