import { FS } from './globals-server'

function v7_get_s3_url (region, bucket, key) {
  if (region === 'us-east-1') {
    return `https://s3.amazonaws.com/${bucket}/${key}`
  }
  return `https://s3-${region}.amazonaws.com/${bucket}/${key}`
}

function v7_get_fileObj (doc, key) {
  let url = v7_get_s3_url(doc.s3_region, doc.s3_bucket, key)
  let fileObj = new FS.File(url)
  return fileObj
}

function impl_6_to_7 (BinaryData, ArchiveFileStore, CacheFileStore) {
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

function impl_7_to_8 (users) {
  return users.find().forEach(doc =>
    users.update(
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

function impl_8_to_9 (roles, users) {
  let permission_map = {
    'admin': ['read', 'write', 'admin'],
    'read-write': ['read', 'write'],
    'read-only': ['read']
  }

  // Remove old roles from Meteor.roles collection
  for (let old_role in permission_map) {
    let doc = roles.findOne({name: old_role})
    if (doc != null) {
      roles.remove({_id: doc._id})
    }
  }

  // Update user docs for new roles
  return users.find().forEach(function (doc) {
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

    return users.update({ _id: doc._id }, {$set: { roles: new_permissions
  }})
  })
}

export const implementations = {
  7: {
    upFunc: impl_6_to_7,
    argNames: ['BinaryData', 'ArchiveFileStore', 'CacheFileStore']
  },
  8: {
    upFunc: impl_7_to_8,
    argNames: ['Meteor.users']
  },
  9: {
    upFunc: impl_8_to_9,
    argNames: ['Meteor.roles', 'Meteor.users']
  }
}
