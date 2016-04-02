import { Meteor } from 'meteor/meteor'
import { Roles } from '../globals-lib'

const NeuronCatalogApp = {}

NeuronCatalogApp.isSandstorm = function (user, roles) {
  if (Meteor.settings != null) {
    if (Meteor.settings.public != null) {
      return Meteor.settings.public.sandstorm
    }
  }
  return false
}

if (!NeuronCatalogApp.isSandstorm()) {
  NeuronCatalogApp.checkRole = Roles.userIsInRole
} else {
  NeuronCatalogApp.checkRole = function (user, roles) {
    // Implement behavior of Roles.userIsInRole for Sandstorm.
    if (!(user != null)) {
      return false
    }
    let doc
    if (typeof user === 'string') {
      doc = Meteor.users.findOne({_id: user})
    }
    if (typeof user === 'object') {
      doc = user
    }

    if (!doc) {
      return false
    }
    if (!(doc.services != null)) {
      return false
    }
    if (!(doc.services.sandstorm != null)) {
      return false
    }
    if (!(doc.services.sandstorm.permissions != null)) {
      return false
    }

    for (let i = 0; i < doc.services.sandstorm.permissions.length; i++) {
      let has_permission = doc.services.sandstorm.permissions[i]
      if (__in__(has_permission, roles)) {
        return true
      }
    }
    return false
  }
}

function __in__ (needle, haystack) {
  return haystack.indexOf(needle) >= 0
}

export { NeuronCatalogApp }
