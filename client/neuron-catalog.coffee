Template.tags_panel.helpers
  TagSearchQuery: ->
    q = {'tags': JSON.stringify([@name])}

Template.MyLayout.helpers
  hasNeededRoles: ->
    # if user has "admin" role or @needPermissions role, authorize
    NeuronCatalogApp.checkRole( Meteor.user(), ["admin", @needPermissions] )
