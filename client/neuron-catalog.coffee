Template.tags_panel.helpers
  TagSearchQuery: ->
    q = {'tags': JSON.stringify([@name])}

Template.ReaderRequiredLayoutWithNamedURL.helpers
  setURL: ->
    # Set the URL bar of the browser to include the @name.
    newPath = Router.current().route.path({_id: @_id, name: @name})
    history.replaceState(null, null, newPath)

Template.MyLayout.helpers
  hasNeededRoles: ->
    # if user has "admin" role or @needPermissions role, authorize
    NeuronCatalogApp.checkRole( Meteor.user(), ["admin", @needPermissions] )
