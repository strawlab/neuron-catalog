import { Meteor } from 'meteor/meteor'

import { DriverLines, BinaryData, NeuronTypes, BrainRegions, ArchiveFileStore, CacheFileStore, NeuronCatalogConfig } from '../lib/model'
import { Migrations } from './globals-server'
import { implementations } from './migrationImplementation'

function parse_s3_url (url) {
  throw new Error('Not Implemented')
  // const result = {
  //   s3_region: 'unknown',
  //   s3_bucket: 'unknown',
  //   s3_key: 'unknown',
  // }
  // return result
}

Migrations.add({
  version: 1,
  name: 'Rename field "last_edit_userId" -> "last_edit_user"',
  up () {
    [DriverLines, NeuronTypes, BrainRegions, BinaryData].forEach(coll => {
      coll.find().forEach(doc => {
        coll.update({
          _id: doc._id
        }, {
          $set: {
            brain_regions: doc.neuropils
          },
          $unset: {
            neuropils: 1
          }
        }, {
          validate: false,
          getAutoValues: false
        })
      })
    })
  }
})

Migrations.add({
  version: 2,
  name: 'Rename collection from neuropils to brain_regions',
  up () {
    let OLDNPILS = new Meteor.Collection('neuropils')

    return OLDNPILS.find().forEach(function (doc) {
      BrainRegions.insert(doc, {validate: false, getAutoValues: false})
      return OLDNPILS.remove({_id: doc._id})
    })
  }
})

Migrations.add({
  version: 3,
  name: 'Rename field from neuropils to brain_regions',
  up () {
    [DriverLines, NeuronTypes].forEach(coll => {
      coll.find().forEach(doc => {
        coll.update({
          _id: doc._id
        }, {
          $set: {
            brain_regions: doc.neuropils
          },
          $unset: {
            neuropils: 1
          }
        }, {
          validate: false,
          getAutoValues: false
        })
      })
    })
  }
})

Migrations.add({
  version: 4,
  name: 'Store S3 bucket name, region, key separately',
  up () {
    return BinaryData.find().forEach(function (doc) {
      let parsed = parse_s3_url(doc.secure_url)
      return BinaryData.update(
        {_id: doc._id}
      , {
        $set: {
          s3_region: parsed.s3_region,
          s3_bucket: parsed.s3_bucket,
          s3_key: parsed.s3_key,
          s3_upload_done: true
        },

        $unset: {
          secure_url: 1
        }
      }
      , {
        validate: false,
        getAutoValues: false
      })
    })
  }
})

Migrations.add({
  version: 5,
  name: 'NeuronCatalogConfig has fixed _id',
  up () {
    let n_docs = NeuronCatalogConfig.find().count()
    if (n_docs === 0) {
      return
    }
    if (n_docs > 1) {
      throw Error('more than one config document')
    }
    let doc = NeuronCatalogConfig.findOne()
    if (doc._id === 'config') {
      return
    }
    let orig_id = doc._id
    doc._id = 'config'
    NeuronCatalogConfig.insert(doc)
    return NeuronCatalogConfig.remove({_id: orig_id})
  }
})

Migrations.add({
  version: 6,
  name: 'Store S3 key for binary_data cache and thumbs',
  up () {
    return BinaryData.find().forEach(function (doc) {
      if (doc.cache_src != null) {
        var parsed = parse_s3_url(doc.cache_src)
        BinaryData.update(
          {_id: doc._id}
        , {
          $set: {
            cache_s3_key: parsed.s3_key
          },

          $unset: {
            cache_src: 1
          }
        }
        , {
          validate: false,
          getAutoValues: false
        })
      }

      if (doc.thumb_src != null) {
        var parsed2 = parse_s3_url(doc.thumb_src)
        return BinaryData.update(
          {_id: doc._id}
        , {
          $set: {
            thumb_s3_key: parsed2.s3_key
          },

          $unset: {
            thumb_src: 1
          }
        }
        , {
          validate: false,
          getAutoValues: false
        })
      }
    })
  }
})

function arraysEqual (a, b) {
  // from http://stackoverflow.com/a/16436975/1633026
  if (a === b) return true
  if (a == null || b == null) return false
  if (a.length !== b.length) return false

  // If you don't care about the order of the elements inside
  // the array, you should sort both arrays here.

  for (var i = 0; i < a.length; ++i) {
    if (a[i] !== b[i]) return false
  }
  return true
}

function assert (value) {
  if (!value) {
    throw new Error('assertion failed')
  }
}

Migrations.add({
  version: 7,
  name: 'Use CollectionFS rather than S3',
  up () {
    const impl = implementations[7]
    assert(arraysEqual(impl.argNames, ['BinaryData', 'ArchiveFileStore', 'CacheFileStore']))
    return impl.upFunc(BinaryData, ArchiveFileStore, CacheFileStore)
  }
})

Migrations.add({
  version: 8,
  name: 'Add .profile.name field to user docs',
  up () {
    const impl = implementations[8]
    assert(arraysEqual(impl.argNames, ['Meteor.users']))
    return impl.upFunc(Meteor.users)
  }
})

Migrations.add({
  version: 9,
  name: 'Rework permissions system',
  up () {
    const impl = implementations[9]
    assert(arraysEqual(impl.argNames, ['Meteor.roles', 'Meteor.users']))
    return impl.upFunc(Meteor.roles, Meteor.users)
  }
})
