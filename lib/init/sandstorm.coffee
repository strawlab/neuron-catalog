if !@NeuronCatalogApp?
  @NeuronCatalogApp = {}

  @NeuronCatalogApp.isSandstorm = (user, roles) ->
    if Meteor.settings?
      if Meteor.settings.public?
        return Meteor.settings.public.sandstorm
    return false

  if !NeuronCatalogApp.isSandstorm()
    @NeuronCatalogApp.checkRole = Roles.userIsInRole
  else
    @NeuronCatalogApp.checkRole = (user, roles) ->
      # Implement behavior of Roles.userIsInRole for Sandstorm.
      if !user?
        return false
      if 'string' == typeof user
        doc = Meteor.users.findOne({_id:user})
      if 'object' == typeof user
        doc = user

      if !doc
        return false
      if !doc.services?
        return false
      if !doc.services.sandstorm?
        return false
      if !doc.services.sandstorm.permissions?
        return false

      for has_permission in doc.services.sandstorm.permissions
        if has_permission in roles
          return true
      return false
