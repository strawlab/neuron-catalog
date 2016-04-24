// data model
// Loaded on both the client and the server
import { Meteor } from 'meteor/meteor'
import { NeuronCatalogApp } from './init/sandstorm'
import { FS, SimpleSchema } from '../lib/globals-lib'

export let SettingsToClient = new Meteor.Collection('settings_to_client')
export let NeuronCatalogConfig = new Meteor.Collection('neuron_catalog_config')
export let DriverLines = new Meteor.Collection('driver_lines')
export let BinaryData = new Meteor.Collection('binary_data')
export let NeuronTypes = new Meteor.Collection('neuron_types')
export let BrainRegions = new Meteor.Collection('brain_regions')
export let ArchiveFileStore = new FS.Collection('archive_filestore', {
  stores: [new FS.Store.GridFS('archive_gridfs')]
})
export let CacheFileStore = new FS.Collection('cache_filestore', {
  stores: [new FS.Store.GridFS('cache_gridfs')]
})

let store_opts = {}
if (Meteor.isServer && NeuronCatalogApp.isSandstorm()) {
  store_opts.path = '/var'
}
export let ZipFileStore = new FS.Collection('zip_filestore', {
  stores: [new FS.Store.FileSystem('zip_files', store_opts)]
})

// ----------------------------------------
export let ReaderRoles = ['read', 'admin']
export let WriterRoles = ['write', 'admin']

// define our schemas

export let Schemas = {}

Schemas.NeuronCatalogConfig = new SimpleSchema({
  project_name: {
    type: String,
    label: 'A short string giving the name of the project'
  },

  data_authors: {
    type: String,
    label: 'A short string giving the name of the contributors to the data. Can contain raw HTML.'
  },

  blurb: {
    type: String,
    label: 'An optional string with more information describing the project. Can contain raw HTML.',
    optional: true
  },

  NeuronCatalogSpecialization: {
    type: String,
    label: 'An optional value enabling species-specific specializations.',
    allowedValues: ['Drosophila melanogaster'],
    autoform: { afFieldInput: { firstOption: '(Select a specialization)'
      }
    },
    optional: true
  },

  DefaultUserRole: {
    type: String,
    label: 'What role new users are given.',
    allowedValues: ['none', 'reader', 'editor'],
    autoform: { afFieldInput: { firstOption: '(Select role for new users)'
      }
    },
    optional: true
  }
}

)
NeuronCatalogConfig.attachSchema(Schemas.NeuronCatalogConfig)

let shallow_copy = function (obj) {
  let newobj = {}
  for (let attrname in obj) {
    newobj[attrname] = obj[attrname]
  }
  return newobj
}

let compose = function (...objects) {
  // This merges N objects while making shallow copies one level deep.
  let result = {}
  for (let i = 0; i < objects.length; i++) {
    let obj = objects[i]
    for (let attrname in obj) {
      result[attrname] = shallow_copy(obj[attrname])
    }
  }
  return result
}

let NamedWithTagsHistoryComments = {
  _id: {
    type: String,
    optional: true // let Meteor/Mongo create one if not specified
  },

  name: {
    type: String
  },

  tags: {
    label: 'Tags',
    type: [String]
  },

  'tags.$': {
    type: String
  },

  // Force value to be current date (on server) upon update.
  last_edit_time: {
    type: Number,
    autoValue () {
      return Date.now()
    }
  },

  // Force value to be current user upon update.
  last_edit_user: {
    type: String,
    autoValue () {
      return this.userId
    }
  },

  // Automatically update a history array.
  edits: {
    type: [Object],
    autoValue () {
      if (this.isInsert) {
        return [{
          time: Date.now(),
          userId: this.userId
        }
        ]
      } else {
        return {
          $push: {
            time: Date.now(),
            userId: this.userId
          }
        }
      }
    }
  },

  'edits.$.time': {
    type: Number,
    optional: true
  },

  'edits.$.userId': {
    type: String,
    optional: true
  },

  comments: {
    type: [Object]
  },

  'comments.$.comment': {
    type: String
  },

  'comments.$.time': {
    type: Number,
    autoValue () {
      return Date.now()
    }
  },

  'comments.$.userId': {
    type: String,
    autoValue () {
      return this.userId
    }
  }
}

let LinksImages = {
  images: {
    label: 'Images and volumes',
    type: [String]
  },

  'images.$': {
    type: String,
    label: '_id of doc in BinaryData collection'
  }
}

let NamedWithTagsImagesHistoryComments = compose(NamedWithTagsHistoryComments, LinksImages)

let LinksNeuronTypes = {
  neuron_types: {
    type: [String]
  },

  'neuron_types.$': {
    type: String,
    label: '_id of doc in NeuronTypes collection'
  }
}

let LinksBrainRegions = {
  brain_regions: {
    type: [Object]
  },

  'brain_regions.$._id': {
    type: String,
    label: '_id of doc in BrainRegions collection'
  },

  'brain_regions.$.type': {
    type: [String]
  },

  'brain_regions.$.type.$': {
    type: String,
    allowedValues: ['input', 'output', 'unspecified']
  }
}

let HasSynonyms = {
  synonyms: {
    type: [String]
  },

  'synonyms.$': {
    type: String,
    label: 'synonym to name'
  }
}

let HasBestDriverLines = {
  best_driver_lines: {
    type: [String]
  },

  'best_driver_lines.$': {
    type: String,
    label: '_id of doc in DriverLines collection'
  }
}

let HasFlyCircuitIdids = {
  flycircuit_idids: {
    type: [Number]
  },

  'flycircuit_idids.$': {
    type: Number,
    label: 'idid value in Flycircuit.tw database'
  }
}

// Schemas.DriverLines -------------------
Schemas.DriverLines = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, LinksNeuronTypes, HasFlyCircuitIdids, LinksBrainRegions))
DriverLines.attachSchema(Schemas.DriverLines)

// Schemas.NeuronTypes ------------------
Schemas.NeuronTypes = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, HasSynonyms, HasBestDriverLines, HasFlyCircuitIdids, LinksBrainRegions))
NeuronTypes.attachSchema(Schemas.NeuronTypes)

// Schemas.BrainRegions ------------------

let DrosophilaBrainRegions = {
  DAO_id: {
    type: String,
    label: 'Drosophila Anatomy Ontology short form identifier',
    optional: true
  }
}

Schemas.BrainRegions = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, DrosophilaBrainRegions))
BrainRegions.attachSchema(Schemas.BrainRegions)

// Schemas.BinaryData ------------------
//  This schema has grown organically and should be cleaned up!
let BinaryDataSpec = {
  archiveId: {
    type: String,
    label: '_id of doc in ArchiveFileStore collection'
  },
  lastModifiedDate: {
    type: Date
  },
  thumbId: {
    type: String,
    label: '_id of doc of thumbnail image in CacheFileStore collection',
    optional: true
  },
  thumb_width: {
    type: Number,
    optional: true
  },
  thumb_height: {
    type: Number,
    optional: true
  },
  width: {
    type: Number,
    optional: true
  },
  height: {
    type: Number,
    optional: true
  },
  cacheId: {
    type: String,
    label: '_id of doc of fullsize image in CacheFileStore collection',
    optional: true
  },
  cache_width: {
    type: Number,
    optional: true
  },
  cache_height: {
    type: Number,
    optional: true
  },
  type: {
    type: String,
    optional: true
  }
}

Schemas.BinaryData = new SimpleSchema(
  compose(NamedWithTagsHistoryComments, BinaryDataSpec))
BinaryData.attachSchema(Schemas.BinaryData)

Schemas.UserProfile = new SimpleSchema({
  name: {
    type: String
  }
}
)

Schemas.User = new SimpleSchema({
  username: {
    type: String,
    regEx: /^[a-z0-9A-Z_\.]{3,15}$/
  },
  profile: {
    type: Schemas.UserProfile
  },
  emails: {
    type: [ Object ],
    optional: true
  },
  'emails.$.address': {
    type: String,
    regEx: SimpleSchema.RegEx.Email
  },
  'emails.$.verified': { type: Boolean
  },
  createdAt: {
    type: Date,
    denyUpdate: true
  },
  services: {
    type: Object,
    optional: true,
    blackbox: true
  },
  roles: {
    type: [String],
    optional: true,
    blackbox: true
  }
}
)

if (!NeuronCatalogApp.isSandstorm()) {
  Meteor.users.attachSchema(Schemas.User)
}
