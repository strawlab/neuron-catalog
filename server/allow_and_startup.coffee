Meteor.startup ->
  # create initial config document if it does not exist
  if NeuronCatalogConfig.find().count() is 0
    doc =
      _id: "config"
      project_name: "neuron catalog"
      data_authors: "authors"
      blurb: ""
    NeuronCatalogConfig.insert doc

  # send relevant Meteor.settings
  SettingsToClient.update( {_id: 'settings'},
    {$set: {specializations: Meteor.settings.NeuronCatalogSpecializations}},
    {upsert: true})

  # ensure first user is in the admin group
  first_user_doc = Meteor.users.findOne({}, {sort: {createdAt: 1}})
  Roles.addUsersToRoles(first_user_doc._id, ['admin'])

  # Ensure existance of roles we use.
  for role_name in ['admin','read-write','read-only']
    if Meteor.roles.find({name: role_name}).count()==0
      Meteor.roles.insert({name: role_name})

# ----------------------------------------
ReaderRoles = ['admin','read-write','read-only']
WriterRoles = ['admin','read-write']

# ----------------------------------------
Meteor.publish "settings_to_client", ->
  SettingsToClient.find {}
Meteor.publish "neuron_catalog_config", ->
  NeuronCatalogConfig.find {}

Meteor.publish "driver_lines", ->
  DriverLines.find {}  if Roles.userIsInRole(@userId, ReaderRoles)
Meteor.publish "neuron_types", ->
  NeuronTypes.find {}  if Roles.userIsInRole(@userId, ReaderRoles)
Meteor.publish "brain_regions", ->
  BrainRegions.find {}  if Roles.userIsInRole(@userId, ReaderRoles)
Meteor.publish "binary_data", ->
  BinaryData.find {}  if Roles.userIsInRole(@userId, ReaderRoles)

# ----------------------------------------

Meteor.publish "userData", ->
  if Roles.userIsInRole(@userId, ReaderRoles)
    Meteor.users.find {},
      fields:
        username: 1

# ----------------------------------------

logged_in_allow =
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, WriterRoles)

  update: (userId, doc, fields, modifier) ->
    Roles.userIsInRole(userId, WriterRoles)

  remove: (userId, doc) ->
    Roles.userIsInRole(userId, WriterRoles)

DriverLines.allow logged_in_allow
BinaryData.allow logged_in_allow
NeuronTypes.allow logged_in_allow
BrainRegions.allow logged_in_allow

NeuronCatalogConfig.allow(
  insert: (userId, doc) ->
    Roles.userIsInRole(userId, ['admin'])

  update: (userId, doc, fields, modifier) ->
    Roles.userIsInRole(userId, ['admin'])

  remove: (userId, doc) ->
    Roles.userIsInRole(userId, ['admin'])
)
