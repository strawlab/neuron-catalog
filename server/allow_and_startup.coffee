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
Meteor.publish "brain_regions", ->
  BrainRegions.find {}  if @userId
Meteor.publish "binary_data", ->
  BinaryData.find {}  if @userId
Meteor.publish "upload_processor_status", ->
  # We test if status document is less than 10 seconds old. We must
  # do this test on the server to deal with cases in which the
  # client and server clocks are not synchronized.
  # Only return document if server is OK.

  # Ugh, to get this to work, I had to include the javascript
  # definition as a string. This seems to be undocumented.
  found = UploadProcessorStatus.find($where: 'function() { var diff_msec, doc_time  , now;        doc_time = new Date(this.time);         now = Date.now();         diff_msec = now - doc_time;             if (diff_msec < 10000) {           return true;         }         return false;      }')
  found

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
UploadProcessorStatus.allow logged_in_allow

NeuronCatalogConfig.allow logged_in_allow
