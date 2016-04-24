import { Meteor } from 'meteor/meteor'

export function isSandstorm () {
  if (Meteor.isServer) {
    return JSON.parse(process.env.SANDSTORM || '0')
  }

  if (Meteor.settings && Meteor.settings.public) {
    return Meteor.settings.public.sandstorm
  }
  return false
}

export function toUserSchema (sandstormUserDoc) {
  // our User schema has things in the `profile` object.
  return {profile: sandstormUserDoc}
}

export function sandstormCheckRole (doc, roles) {
  // Implement behavior of Roles.userIsInRole for Sandstorm.
  if (doc && doc.profile && doc.profile.permissions) {
    const permissions = doc.profile.permissions
    for (let i = 0; i < permissions.length; i++) {
      let has_permission = permissions[i]
      if (roles.indexOf(has_permission) >= 0) {
        return true
      }
    }
  }
  return false
}
