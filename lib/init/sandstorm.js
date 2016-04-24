import { Meteor } from 'meteor/meteor'

export function isSandstorm () {
  if (Meteor.settings && Meteor.settings.public) {
    return Meteor.settings.public.sandstorm
  }
  return false
}

export function sandstormCheckRole (user, roles) {
  // Implement behavior of Roles.userIsInRole for Sandstorm.
  const doc = (typeof user === 'string') ? Meteor.users.findOne({_id: user}) : user

  if (doc && doc.services && doc.services.sandstorm && doc.services.sandstorm.permissions) {
    for (let i = 0; i < doc.services.sandstorm.permissions.length; i++) {
      let has_permission = doc.services.sandstorm.permissions[i]
      if (roles.indexOf(has_permission) >= 0) {
        return true
      }
    }
  }
  return false
}
