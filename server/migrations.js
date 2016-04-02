import { Meteor } from 'meteor/meteor'

import { DriverLines, BinaryData, NeuronTypes, BrainRegions, ArchiveFileStore, CacheFileStore, NeuronCatalogConfig } from '../lib/model'
import { FS, Migrations } from './globals-server'

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

let v7_get_s3_url = function (region, bucket, key) {
  if (region === 'us-east-1') {
    return `https://s3.amazonaws.com/${bucket}/${key}`
  }
  return `https://s3-${region}.amazonaws.com/${bucket}/${key}`
}

let v7_get_fileObj = function (doc, key) {
  let url = v7_get_s3_url(doc.s3_region, doc.s3_bucket, key)
  let fileObj = new FS.File(url)
  return fileObj
}

Migrations.add({
  version: 7,
  name: 'Use CollectionFS rather than S3',
  up () {
    return BinaryData.find().forEach(function (doc) {
      let setters = {}
      let removers = {
        s3_bucket: 1,
        s3_region: 1,
        s3_upload_done: 1
      }

      let fileObjArchive = ArchiveFileStore.insert(v7_get_fileObj(doc, doc.s3_key))
      setters.archiveId = fileObjArchive._id
      removers.s3_key = 1

      if (doc.thumb_s3_key) {
        let fileObjThumb = CacheFileStore.insert(v7_get_fileObj(doc, doc.thumb_s3_key))
        setters.thumbId = fileObjThumb._id
        removers.thumb_s3_key = 1
      }

      if (doc.cache_s3_key) {
        let fileObjCache = CacheFileStore.insert(v7_get_fileObj(doc, doc.cache_s3_key))
        setters.cacheId = fileObjCache._id
        removers.cache_s3_key = 1
      }

      return BinaryData.update({ _id: doc._id }, {
        $set: setters,
        $unset: removers
      }, {
        validate: false,
        getAutoValues: false
      })
    })
  }
})

Migrations.add({
  version: 8,
  name: 'Add .profile.name field to user docs',
  up () {
    return Meteor.users.find().forEach(doc =>
      Meteor.users.update(
        {_id: doc._id}
      , {
        $set: {
          profile: {
            name: doc.username
          }
        }
      })
    )
  }
})

Migrations.add({
  version: 9,
  name: 'Rework permissions system',
  up () {
    let permission_map = {
      'admin': ['read', 'write', 'admin'],
      'read-write': ['read', 'write'],
      'read-only': ['read']
    }

    // Remove old roles from Meteor.roles collection
    for (let old_role in permission_map) {
      let doc = Meteor.roles.findOne({name: old_role})
      if (doc != null) {
        Meteor.roles.remove({_id: doc._id})
      }
    }

    // Update user docs for new roles
    return Meteor.users.find().forEach(function (doc) {
      // use object to prevent repeated keys
      let new_permissions = {}
      for (let i = 0; i < doc.roles.length; i++) {
        let old_permission = doc.roles[i]
        for (let j = 0; j < permission_map[old_permission].length; j++) {
          let new_permission = permission_map[old_permission][j]
          new_permissions[new_permission] = true
        }
      }
      new_permissions = Object.keys(new_permissions)

      return Meteor.users.update({ _id: doc._id }, {$set: { roles: new_permissions
    }})
    })
  }
})
