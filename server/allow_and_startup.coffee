Meteor.startup ->
  Migrations.migrateTo(9)

  # create initial config document if it does not exist
  if NeuronCatalogConfig.find().count() is 0
    doc =
      _id: "config"
      project_name: "neuron catalog"
      data_authors: "authors"
      blurb: ""
    NeuronCatalogConfig.insert doc

  # Send relevant Meteor.settings.
  # SECURITY NOTE: These are visible to all site visitors, even those
  # not in a ReaderRole. So don't add any sensitive information here.
  SettingsToClient.update( {_id: 'settings'},
    {$set:
       SchemaVersion: Migrations.getVersion()
    },
    {upsert: true})

  # Ensure existance of permissions we use.
  for permission_name in ['admin','write','read']
    if Meteor.roles.find({name: permission_name}).count()==0
      Meteor.roles.insert({name: permission_name})

# ----------------------------------------
Meteor.publish "settings_to_client", ->
  SettingsToClient.find {}
Meteor.publish "neuron_catalog_config", ->
  NeuronCatalogConfig.find {} if NeuronCatalogApp.checkRole(@userId, ReaderRoles)

Meteor.publish "driver_lines", ->
  DriverLines.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
Meteor.publish "neuron_types", ->
  NeuronTypes.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
Meteor.publish "brain_regions", ->
  BrainRegions.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
Meteor.publish "binary_data", ->
  BinaryData.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)

Meteor.publish "archive_filestore", ->
  ArchiveFileStore.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
Meteor.publish "cache_filestore", ->
  CacheFileStore.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
Meteor.publish "zip_filestore", ->
  ZipFileStore.find {}  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)

# ----------------------------------------

Meteor.publish "userData", ->
  if NeuronCatalogApp.checkRole(@userId, ReaderRoles)
    Meteor.users.find {},
      fields:
        profile: 1

# ----------------------------------------

logged_in_allow =
  insert: (userId, doc) ->
    NeuronCatalogApp.checkRole(userId, WriterRoles)
  update: (userId, doc, fields, modifier) ->
    NeuronCatalogApp.checkRole(userId, WriterRoles)
  remove: (userId, doc) ->
    NeuronCatalogApp.checkRole(userId, WriterRoles)

DriverLines.allow logged_in_allow
BinaryData.allow logged_in_allow
NeuronTypes.allow logged_in_allow
BrainRegions.allow logged_in_allow
ArchiveFileStore.allow
  insert: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  update: (userId, doc, fields, modifier) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  remove: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  download: (userId, fileObj) ->
    NeuronCatalogApp.checkRole userId, ReaderRoles
CacheFileStore.allow
  insert: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  update: (userId, doc, fields, modifier) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  remove: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  download: (userId, fileObj) ->
    NeuronCatalogApp.checkRole userId, ReaderRoles
ZipFileStore.allow
  insert: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  update: (userId, doc, fields, modifier) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  remove: (userId, doc) ->
    NeuronCatalogApp.checkRole userId, WriterRoles
  download: (userId, fileObj) ->
    NeuronCatalogApp.checkRole userId, ReaderRoles

NeuronCatalogConfig.allow(
  insert: (userId, doc) ->
    NeuronCatalogApp.checkRole(userId, ['admin'])

  update: (userId, doc, fields, modifier) ->
    NeuronCatalogApp.checkRole(userId, ['admin'])

  remove: (userId, doc) ->
    NeuronCatalogApp.checkRole(userId, ['admin'])
)

get_default_permissions = () ->
  doc = NeuronCatalogConfig.findOne({_id:"config"})
  if !doc?
    return []
  if !doc.DefaultUserRole?
    return []
  if doc.DefaultUserRole == "none"
    return []
  if doc.DefaultUserRole == "reader"
    return ["read"]
  if doc.DefaultUserRole == "editor"
    return ["read","write"]
  return []

if !NeuronCatalogApp.isSandstorm()
  Accounts.onCreateUser (options, user) ->
    if Meteor.users.find().count()==0
      # first user is always admin
      role_names = ['admin']
    else
      # get the roles from the settings
      role_names = get_default_permissions()

    # add default roles
    user.roles = user.roles || []
    for role_name in role_names
      if !(role_name in user.roles)
        user.roles.push role_name

    # Validate roles
    for role_name in user.roles
      if role_name not in ['admin','write','read']
        throw new Error("invalid role name: "+role_name)

    # Set default profile.name value
    user.profile = user.profile || {}
    user.profile.name = user.profile.name || user.username

    user
