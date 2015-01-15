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
    label: "A short string giving the name of the project"

  data_authors:
    type: String
    label: "A short string giving the name of the contributors to the data"

  blurb:
    type: String
    label: "An optional string with more information describing the project. Can contain raw HTML."
    optional: true
)
NeuronCatalogConfig.attachSchema(Schemas.NeuronCatalogConfig)

shallow_copy = (obj) ->
  newobj = {}
  for attrname of obj
    newobj[attrname] = obj[attrname]
  newobj

compose = (objects...) ->
  # This merges N objects while making shallow copies one level deep.
  result = {}
  for obj in objects
    for attrname of obj
      result[attrname] = shallow_copy(obj[attrname])
  result

NamedWithTagsHistoryComments =
  _id:
    type: String
    optional: true # let Meteor/Mongo create one if not specified

  name:
    type: String

  tags:
    label: "Tags"
    type: [String]

  "tags.$":
    type: String

  # Force value to be current date (on server) upon update.
  last_edit_time:
    type: Number
    autoValue: ->
      Date.now()

  # Force value to be current user upon update.
  last_edit_userId:
    type: String
    autoValue: ->
      @userId

  # Automatically update a history array.
  edits:
    type: [Object]
    autoValue: ->
      if @isInsert
        [
          time: Date.now()
          userId: @userId
        ]
      else
        $push:
          time: Date.now()
          userId: @userId

  "edits.$.time":
    type: Number
    optional: true

  "edits.$.userId":
    type: String
    optional: true

  comments:
    type: [Object]

  "comments.$.comment":
    type: String

  "comments.$.time":
    type: Number
    autoValue: ->
      Date.now()

  "comments.$.userId":
    type: String
    autoValue: ->
      @userId

LinksImages =
  images:
    label: "Images and volumes"
    type: [String]

  "images.$":
    type: String
    label: "_id of doc in BinaryData collection"

NamedWithTagsImagesHistoryComments = compose(NamedWithTagsHistoryComments,LinksImages)

LinksNeuronTypes =
  neuron_types:
    type: [String]

  "neuron_types.$":
    type: String
    label: "_id of doc in NeuronTypes collection"

LinksNeuropils =
  neuropils:
    type: [Object]

  "neuropils.$._id":
    type: String
    label: "_id of doc in Neuropils collection"

  "neuropils.$.type":
    type: [String]

  "neuropils.$.type.$":
    type: String
    allowedValues: ["input", "output", "unspecified"]

HasSynonyms =
  synonyms:
    type: [String]

  "synonyms.$":
    type: String
    label: "synonym to name"

HasBestDriverLines =
  best_driver_lines:
    type: [String]

  "best_driver_lines.$":
    type: String
    label: "_id of doc in DriverLines collection"

HasFlyCircuitIdids =
  flycircuit_idids:
    type: [Number]

  "flycircuit_idids.$":
    type: Number
    label: "idid value in Flycircuit.tw database"

# Schemas.DriverLines -------------------
Schemas.DriverLines = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, LinksNeuronTypes, HasFlyCircuitIdids, LinksNeuropils))
DriverLines.attachSchema( Schemas.DriverLines )

# Schemas.NeuronTypes ------------------
Schemas.NeuronTypes = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments, HasSynonyms, HasBestDriverLines, HasFlyCircuitIdids, LinksNeuropils))
NeuronTypes.attachSchema( Schemas.NeuronTypes )

# Schemas.Neuropils ------------------
Schemas.Neuropils = new SimpleSchema(
  compose(NamedWithTagsImagesHistoryComments))
Neuropils.attachSchema( Schemas.Neuropils )

# Schemas.BinaryData ------------------
#  This schema has grown organically and should be cleaned up!
BinaryDataSpec =
  thumb_src:
    type: String
    optional: true
  secure_url:
    type: String
  lastModifiedDate:
    type: Date
  thumb_width:
    type: Number
    optional: true
  thumb_height:
    type: Number
    optional: true
  width:
    type: Number
    optional: true
  height:
    type: Number
    optional: true
  cache_width:
    type: Number
    optional: true
  cache_height:
    type: Number
    optional: true
  cache_src:
    type: String
    optional: true
  type:
    type: String
    optional: true

Schemas.BinaryData = new SimpleSchema(
  compose(NamedWithTagsHistoryComments,BinaryDataSpec))
BinaryData.attachSchema( Schemas.BinaryData )

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
