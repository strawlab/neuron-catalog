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
  return

# ----------------------------------------
Meteor.publish "settings_to_client", ->
  SettingsToClient.find {}
Meteor.publish "neuron_catalog_config", ->
  NeuronCatalogConfig.find {}

Meteor.publish "driver_lines", ->
  DriverLines.find {}  if @userId
Meteor.publish "neuron_types", ->
  NeuronTypes.find {}  if @userId
Meteor.publish "brain_regions", ->
  BrainRegions.find {}  if @userId
Meteor.publish "binary_data", ->
  BinaryData.find {}  if @userId

# ----------------------------------------

Meteor.publish "userData", ->
  if @userId
    Meteor.users.find {},
      fields:
        username: 1

# ----------------------------------------

logged_in_allow =
  insert: (userId, doc) ->
    !!userId

  update: (userId, doc, fields, modifier) ->
    !!userId

  remove: (userId, doc) ->
    !!userId

DriverLines.allow logged_in_allow
BinaryData.allow logged_in_allow
NeuronTypes.allow logged_in_allow
BrainRegions.allow logged_in_allow

NeuronCatalogConfig.allow logged_in_allow
