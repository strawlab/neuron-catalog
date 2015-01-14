# data model
# Loaded on both the client and the server

@NeuronCatalogConfig = new Meteor.Collection("neuron_catalog_config")
@DriverLines = new Meteor.Collection("driver_lines")
@BinaryData = new Meteor.Collection("binary_data")
@NeuronTypes = new Meteor.Collection("neuron_types")
@Neuropils = new Meteor.Collection("neuropils")

# Create a capped collection to describe the upload processor status.
@UploadProcessorStatus = new Meteor.Collection("upload_processor_status")

# define our schemas

Schemas = {}
Schemas.NeuronCatalogConfig = new SimpleSchema(
  project_name:
    type: String
    label: "project_name"

  data_authors:
    type: String
    label: "data_authors"

  blurb:
    type: String
    label: "blurb"
    optional: true
)
NeuronCatalogConfig.attachSchema(Schemas.NeuronCatalogConfig);

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
  Meteor.publish "upload_processor_status", ->
    # We test if status document is less than 10 seconds old. We must
    # do this test on the server to deal with cases in which the
    # client and server clocks are not synchronized.
    # Only return document if server is OK.

    # Ugh, to get this to work, I had to include the javascript
    # definition as a string. This seems to be undocumented.
    found = UploadProcessorStatus.find($where: 'function() { var diff_msec, doc_time, now;        doc_time = new Date(this.time);         now = Date.now();         diff_msec = now - doc_time;             if (diff_msec < 10000) {           return true;         }         return false;      }')
    found

  Meteor.publish "userData", ->
    Meteor.users.find {},
      fields:
        username: 1

  # ----------------------------------------

  insert_hook = (userId, doc) ->
    now = Date.now()
    doc.edits = [{'time':now,'userId':userId}]
    doc.last_edit_time = now
    doc.last_edit_userId = userId
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

    modifier.$set = modifier.$set or {}
    modifier.$set.last_edit_time = now
    modifier.$set.last_edit_userId = userId

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
  UploadProcessorStatus.allow logged_in_allow
