import { Meteor } from 'meteor/meteor'
import { Roles } from '../lib/globals-lib'
import { DriverLines, BinaryData, NeuronTypes, BrainRegions, ArchiveFileStore, CacheFileStore, ZipFileStore, NeuronCatalogConfig, SettingsToClient, ReaderRoles, WriterRoles } from '../lib/model'
import { Accounts, Migrations } from './globals-server'
import { isSandstorm, sandstormCheckRole } from '../lib/init/sandstorm'

function checkRole (user, roles) {
  if (isSandstorm()) {
    return sandstormCheckRole(user, roles)
  } else {
    return Roles.userIsInRole(user, roles)
  }
}

Meteor.startup(function () {
  Migrations.migrateTo('latest')

  if (isSandstorm()) {
    // Tell clients they are in sandstorm.
    Meteor.settings.public.sandstorm = true
  }

  // create initial config document if it does not exist
  if (NeuronCatalogConfig.find().count() === 0) {
    let doc = {
      _id: 'config',
      project_name: 'neuron catalog',
      data_authors: 'authors',
      blurb: ''
    }
    NeuronCatalogConfig.insert(doc)
  }

  // Send relevant Meteor.settings.
  // SECURITY NOTE: These are visible to all site visitors, even those
  // not in a ReaderRole. So don't add any sensitive information here.
  SettingsToClient.update({_id: 'settings'},
    {$set: {SchemaVersion: Migrations.getVersion()}
    },
    {upsert: true})

  // Ensure existance of permissions we use.
  const permission_names = ['admin', 'write', 'read']
  permission_names.forEach(permission_name => {
    if (Meteor.roles.find({name: permission_name}).count() === 0) {
      Meteor.roles.insert({name: permission_name})
    }
  })
})

// ----------------------------------------
Meteor.publish('settings_to_client', () => SettingsToClient.find({}))
Meteor.publish('neuron_catalog_config', function () {
  if (checkRole(this.userId, ReaderRoles)) { return NeuronCatalogConfig.find({}) }
})

Meteor.publish('driver_lines', function () {
  if (checkRole(this.userId, ReaderRoles)) { return DriverLines.find({}) }
})
Meteor.publish('neuron_types', function () {
  if (checkRole(this.userId, ReaderRoles)) { return NeuronTypes.find({}) }
})
Meteor.publish('brain_regions', function () {
  if (checkRole(this.userId, ReaderRoles)) { return BrainRegions.find({}) }
})
Meteor.publish('binary_data', function () {
  if (checkRole(this.userId, ReaderRoles)) { return BinaryData.find({}) }
})

Meteor.publish('archive_filestore', function () {
  if (checkRole(this.userId, ReaderRoles)) { return ArchiveFileStore.find({}) }
})
Meteor.publish('cache_filestore', function () {
  if (checkRole(this.userId, ReaderRoles)) { return CacheFileStore.find({}) }
})
Meteor.publish('zip_filestore', function () {
  if (checkRole(this.userId, ReaderRoles)) { return ZipFileStore.find({}) }
})

// ----------------------------------------

Meteor.publish('userData', function () {
  if (checkRole(this.userId, ReaderRoles)) {
    return Meteor.users.find({}, {
      fields: {
        profile: 1
      }
    })
  }
})

// ----------------------------------------

let logged_in_allow = {
  insert (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  update (userId, doc, fields, modifier) {
    return checkRole(userId, WriterRoles)
  },
  remove (userId, doc) {
    return checkRole(userId, WriterRoles)
  }
}

DriverLines.allow(logged_in_allow)
BinaryData.allow(logged_in_allow)
NeuronTypes.allow(logged_in_allow)
BrainRegions.allow(logged_in_allow)
ArchiveFileStore.allow({
  insert (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  update (userId, doc, fields, modifier) {
    return checkRole(userId, WriterRoles)
  },
  remove (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  download (userId, fileObj) {
    return checkRole(userId, ReaderRoles)
  }
})
CacheFileStore.allow({
  insert (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  update (userId, doc, fields, modifier) {
    return checkRole(userId, WriterRoles)
  },
  remove (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  download (userId, fileObj) {
    return checkRole(userId, ReaderRoles)
  }
})
ZipFileStore.allow({
  insert (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  update (userId, doc, fields, modifier) {
    return checkRole(userId, WriterRoles)
  },
  remove (userId, doc) {
    return checkRole(userId, WriterRoles)
  },
  download (userId, fileObj) {
    return checkRole(userId, ReaderRoles)
  }
})

NeuronCatalogConfig.allow({
  insert (userId, doc) {
    return checkRole(userId, ['admin'])
  },

  update (userId, doc, fields, modifier) {
    return checkRole(userId, ['admin'])
  },

  remove (userId, doc) {
    return checkRole(userId, ['admin'])
  }
}
)

let get_default_permissions = function () {
  let doc = NeuronCatalogConfig.findOne({_id: 'config'})
  if (!(doc != null)) {
    return []
  }
  if (!(doc.DefaultUserRole != null)) {
    return []
  }
  if (doc.DefaultUserRole === 'none') {
    return []
  }
  if (doc.DefaultUserRole === 'reader') {
    return ['read']
  }
  if (doc.DefaultUserRole === 'editor') {
    return ['read', 'write']
  }
  return []
}

if (!isSandstorm()) {
  Accounts.onCreateUser(function (options, user) {
    let role_names
    if (Meteor.users.find().count() === 0) {
      // first user is always admin
      role_names = ['admin']
    } else {
      // get the roles from the settings
      role_names = get_default_permissions()
    }

    // add default roles
    user.roles = user.roles || []
    role_names.forEach(role_name => {
      if (user.roles.indexOf(role_name) === -1) {
        user.roles.push(role_name)
      }
    })

    // Validate roles
    const valid = ['admin', 'write', 'read']
    user.roles.forEach(role_name => {
      if (valid.indexOf(role_name) === -1) {
        throw new Error('invalid role name: ' + role_name)
      }
    })

    // Set default profile.name value
    user.profile = user.profile || {}
    user.profile.name = user.profile.name || user.username

    return user
  })
}
