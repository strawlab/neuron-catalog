# data model
# Loaded on both the client and the server

#////////////////////////////////////////////////////
@NeuronCatalogConfig = new Meteor.Collection("neuron_catalog_config")

#////////////////////////////////////////////////////
@DriverLines = new Meteor.Collection("driver_lines")

#
#  name: String
#  _id: <int>
#  neuron_types: [id, ...]
#  neuropils: [id, ...]
#  comments: [{[auth_stuff], comment: markdown_string, [timestamp: hmm]}, ...]
#  images: [ BinaryData(id), ... ]
#

#////////////////////////////////////////////////////
@BinaryData = new Meteor.Collection("binary_data")

#
# filename: String
# mimetype: String
# _id: <int>
# data: <blob>
# comments: [{[auth_stuff], comment: markdown_string, [timestamp: hmm]}, ...]
#

#////////////////////////////////////////////////////
@NeuronTypes = new Meteor.Collection("neuron_types")

#
#  name: String
#  _id: <int>
#  synonyms: [String, ...]
#  neuropils: [id, ...]
#  best_driver_lines: [id, ...]
#

#////////////////////////////////////////////////////
@Neuropils = new Meteor.Collection("neuropils")

#
#  name: String
#  _id: <int>
#  x3dom_models: [ BinaryData(id), ... ]
#
if Meteor.isServer

  Meteor.startup ->
    if NeuronCatalogConfig.find().count() is 0
      doc =
        project_name: "neuron catalog"
        data_authors: "authors"
        blurb: ""
      NeuronCatalogConfig.insert doc
    return

  # ----------------------------------------
  Meteor.publish "neuron_catalog_config", ->
    NeuronCatalogConfig.find {}

  Meteor.publish "driver_lines", ->
    DriverLines.find {}  if @userId
  Meteor.publish "neuron_types", ->
    NeuronTypes.find {}  if @userId
  Meteor.publish "neuropils", ->
    Neuropils.find {}  if @userId
  Meteor.publish "binary_data", ->
    BinaryData.find {}  if @userId

  # ----------------------------------------

  insert_hook = (userId, doc) ->
    doc.edits = [{'time':Date.now(),'userId':userId}]
    return

  DriverLines.before.insert insert_hook
  NeuronTypes.before.insert insert_hook
  Neuropils.before.insert insert_hook
  BinaryData.before.insert insert_hook

  update_hook = (userId, doc, fieldNames, modifier, options) ->
    now = Date.now()
    if modifier.$push? and modifier.$push.comments?
        # save comment creation information
        modifier.$push.comments.time = now
        modifier.$push.comments.userId = userId

    modifier.$push = modifier.$push or {}
    modifier.$push.edits = {'time':now,'userId':userId}
    return

  DriverLines.before.update update_hook
  NeuronTypes.before.update update_hook
  Neuropils.before.update update_hook
  BinaryData.before.update update_hook

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
  Neuropils.allow logged_in_allow
