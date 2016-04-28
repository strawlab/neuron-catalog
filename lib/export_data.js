import { Meteor } from 'meteor/meteor'

import {DriverLines, NeuronTypes, BrainRegions, BinaryData, NeuronCatalogConfig, SettingsToClient, ArchiveFileStore, CacheFileStore} from './model'

export function get_collection_from_name (name) {
  switch (name) {
    case 'DriverLines':
      return DriverLines
    case 'NeuronTypes':
      return NeuronTypes
    case 'BrainRegions':
      return BrainRegions
    case 'BinaryData':
      return BinaryData
    case 'Meteor.users':
      return Meteor.users
    case 'NeuronCatalogConfig':
      return NeuronCatalogConfig
    case 'SettingsToClient':
      return SettingsToClient
    default:
      throw new Error(`unknown collection name ${name}`)
  }
}

export function export_data () {
  let collections = {}
  let iterable = ['NeuronCatalogConfig', 'DriverLines', 'NeuronTypes', 'BrainRegions', 'BinaryData', 'Meteor.users', 'SettingsToClient']
  for (let i = 0; i < iterable.length; i++) {
    let collection_name = iterable[i]
    let coll = get_collection_from_name(collection_name)
    let this_coll = {}
    coll.find().forEach(function (doc) {
      if (collection_name === 'Meteor.users') {
        // only save usernames
        doc = {_id: doc._id, profile: {name: doc.profile.name}}
      }
      this_coll[doc._id] = doc
      return this_coll[doc._id]
    })
    collections[collection_name] = this_coll
  }
  let all_data = {collections, 'export_date': new Date().toISOString()}
  return JSON.stringify(all_data)
}

// ----

export function get_fileObj (doc, keyname) {
  let fileObj
  if (keyname === 'archive') {
    fileObj = ArchiveFileStore.findOne({_id: doc.archiveId})
  } else if (keyname === 'cache') {
    fileObj = CacheFileStore.findOne({_id: doc.cacheId})
  } else if (keyname === 'thumb') {
    fileObj = CacheFileStore.findOne({_id: doc.thumbId})
  }
  return fileObj
}
