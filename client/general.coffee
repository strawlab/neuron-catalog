# -------------
# font awesome (see
# https://github.com/nate-strauser/meteor-font-awesome/blob/master/load.js )
head = document.getElementsByTagName("head")[0]

#Generate a style tag
style = document.createElement("link")
style.type = "text/css"
style.rel = "stylesheet"
style.href = "/css/font-awesome.min.css"
head.appendChild style

# -------------
Meteor.subscribe "driver_lines"
Meteor.subscribe "neuron_types"
Meteor.subscribe "neuropils"
Meteor.subscribe "binary_data"
Meteor.subscribe "neuron_catalog_config"
Meteor.subscribe "userData"
Meteor.subscribe "upload_processor_status"

# --------------------------------------------
# session variables
Session.setDefault "editing_name", null
Session.setDefault "editing_add_synonym", null
Session.setDefault "editing_add_tag", null
Session.setDefault "modal_info", null
Session.setDefault "comment_preview_mode", false
Session.setDefault "comment_preview_html", null
Session.setDefault "upload_processor_has_error", false
Session.setDefault "recent_changes_n_days", 2
Session.setDefault "all_tags", []

window.modal_save_func = null
window.modal_shown_callback = null

# --------------------------------------------
# timer functions

update_upload_processor_status = ->
  doc = UploadProcessorStatus.findOne({'_id':'status'})
  if !doc?
    Session.set("upload_processor_has_error",true)
    return

  Session.set("upload_processor_has_error",false)
  return

Meteor.setInterval(update_upload_processor_status, 5000) # check status every 5 seconds

# --------------------------------------------
# helper functions

@endsWith = (str, suffix) ->
  str.indexOf(suffix, str.length - suffix.length) isnt -1

window.get_route_from_name = (name) ->
  route = undefined
  if name is "DriverLines"
    route = Router.routes['driver_line_show']
  else if name is "NeuronTypes"
    route = Router.routes['neuron_type_show']
  else if name is "Neuropils"
    route = Router.routes['neuropil_show']
  else route = Router.routes['binary_data_show']  if name is "BinaryData"
  route

window.get_collection_from_name = (name) ->
  coll = undefined
  if name is "DriverLines"
    coll = DriverLines
  else if name is "NeuronTypes"
    coll = NeuronTypes
  else if name is "Neuropils"
    coll = Neuropils
  else if name is "BinaryData"
    coll = BinaryData
  else if name is "Meteor.users"
    coll = Meteor.users
  else
    console.error "unknown collection name "+name
  coll

# --------------------------------------------
# from: meteor TODO app

# Returns an event map that handles the "escape" and "return" keys and
# "blur" events on a text input (given by selector) and interprets them
# as "ok" or "cancel".
window.okCancelEvents = (selector, callbacks) ->
  ok = callbacks.ok or ->

  cancel = callbacks.cancel or ->

  events = {}
  events["keyup " + selector + ", keydown " + selector + ", focusout " + selector] = (evt) ->
    if evt.type is "keydown" and evt.which is 27

      # escape = cancel
      cancel.call this, evt
    else if evt.type is "keyup" and evt.which is 13 or evt.type is "focusout"

      # blur/return/enter = ok/submit if non-empty
      value = String(evt.target.value or "")
      if value
        ok.call this, value, evt
      else
        cancel.call this, evt
    return

  events

window.activateInput = (input) ->
  input.focus()
  input.select()
  return

window.renderTmp = (template, data) ->
  # see http://stackoverflow.com/a/26309004/1633026
  node = document.createElement("div")
  document.body.appendChild node
  window.dialog_template = UI.renderWithData template, data, node
  node

# --------------------------------------------

Template.raw_document_view.helpers
  raw_document: ->
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id: @my_id})
    JSON.stringify doc, `undefined`, 2

Template.linkout.helpers
  path: ->
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id: @my_id})
    window.get_route_from_name(@collection).path(doc)
  name: ->
    @doc.name

Template.next_previous_button.helpers
  get_linkout: ->
    coll = window.get_collection_from_name(@collection)
    my_doc = coll.findOne({_id:@my_id})
    if !my_doc?
      return
    if @which=="next"
      op = "$gt"
      direction = 1
    else
      op = "$lt"
      direction = -1
      # assert @which=="previous"

    # Did I mention how much I do not understand how JavaScript and
    # Coffeescript automatically quote string literals unless using
    # square brackets?
    sort_key = window.get_sort_key(@collection)
    query = {}
    query[sort_key] = {}
    query[sort_key][op]=my_doc[sort_key]
    sort_options = {}
    sort_options[sort_key]=direction
    options = {limit:1}
    options['sort'] = sort_options
    cursor = coll.find(query,options)
    if cursor.count() == 0
      return
    arr = cursor.fetch()
    doc = arr[0]
    result = {}
    result["collection"]=@collection
    result["my_id"]=doc['_id']
    result["doc"]=doc
    result

Template.UploadProcessorStatus.helpers get_upload_processor_has_error: ->
  Session.get("upload_processor_has_error")

# --------------------------------------------

Template.show_dialog.helpers modal_info: ->
  Session.get("modal_info")

Template.show_dialog.events
  "click .delete": (e) ->
    e.preventDefault()
    info = Session.get("modal_info")
    window.jump_table[info.collection].remove info.my_id
    $("#show_dialog_id").modal "hide"
    route_name = window.jump_table[info.collection].base_route
    Router.go route_name
    return

  "click .save": (event, template) ->
    event.preventDefault()
    info = Session.get("modal_info")
    result = window.modal_save_func(info, template)
    if result.error
      info.error = result.error
      Session.set "modal_info", info
    else
      $("#show_dialog_id").modal "hide"
    return

  "shown.bs.modal": (event, template) ->
    if window.modal_shown_callback?
      info = Session.get("modal_info")
      window.modal_shown_callback(info, template, event)
    return

window.jump_table =
  DriverLines:
    remove: (x) ->
      remove_driver_line x

    delete_template_name: "driver_line_show_brief"
    element_route: "driver_line_show"
    base_route: "driver_lines"
    edit_neuron_types_template_name: "edit_neuron_types"

  NeuronTypes:
    remove: (x) ->
      remove_neuron_type x

    save: (info, template) ->
      save_neuron_type info, template

    delete_template_name: "neuron_type_show_brief"
    element_route: "neuron_type_show"
    base_route: "neuron_types"

  Neuropils:
    remove: (x) ->
      remove_neuropil x

    save: (info, template) ->
      save_neuropil info, template

    delete_template_name: "neuropil_show_brief"
    element_route: "neuropil_show"
    base_route: "neuropils"

  BinaryData:
    remove: (x) ->
      remove_binary_data x

    delete_template_name: "binary_data_show_brief"
    base_route: "binary_data"

Template.top_content_row2.helpers
  editing_name: ->
    d = Session.get("editing_name")
    return false unless d?
    return true if @_id is d._id & @collection is d.collection
    false

Template.top_content_row2.events "click .edit-name": (e, tmpl) ->
  Session.set "editing_name", tmpl.data
  Deps.flush() # update DOM before focus
  ni = tmpl.find("#name-input")
  ni.value = @name
  window.activateInput ni
  return

Template.top_content_row2.events window.okCancelEvents("#name-input",
  ok: (value,evt) ->
    if Session.get("editing_name") == null
      # Hmm, why do we get here? Cancel was clicked.
      return
    coll = window.get_collection_from_name(@collection)
    coll.update @_id,
      $set:
        name: value

    Session.set "editing_name", null
    return

  cancel: (evt) ->
    Session.set "editing_name", null
    return
)

Template.delete_button.events
  "click .delete": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Do you want to delete this?"
      collection: @collection
      my_id: @my_id
      body_template_name: window.jump_table[@collection].delete_template_name
      body_template_data: @my_id
      is_delete_modal: true

    window.modal_save_func = null
    window.modal_shown_callback = null

    $("#show_dialog_id").modal "show"
    return

# -------------

Template.raw_button.events
  "click .raw": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Raw document view"
      collection: @collection
      my_id: @my_id
      body_template_name: "raw_document_view"
      body_template_data:
        collection: @collection
        my_id: @my_id

    window.modal_save_func = null
    window.modal_shown_callback = null
    $("#show_dialog_id").modal "show"
    return

# -------------

Template.show_user_date.helpers
  pretty_username: ->
    doc = Meteor.users.findOne {_id:this.userId}
    if doc? and doc.username?
      return doc.username
    "userID "+this.userId

  pretty_time: ->
    timestamp = Date(this.time)
    moment(this.time).fromNow()

# -------------

Template.show_upload_progress.helpers
  percent_uploaded: ->
    if !window.uploader?
      return
    Math.round(window.uploader.progress() * 100);

# ------- tab layout stuff ----
Template.MyLayout.helpers
  top_margin_class_attrs: ->
    if Session.get("upload_processor_has_error")
      result = 'container-fluid top50'
    else
      result = 'container-fluid'
    result

UI.body.helpers
  getData: ->
    "data"

# --------

Template.registerHelper "get_neuropils", (doc,type) ->
  result = []
  for neuropil in doc.neuropils
    if type in neuropil.type
      result.push neuropil
  result

Template.registerHelper "activeIfTemplateIn", () ->
  currentRoute = Router.current()
  if currentRoute
    for arg in arguments
      if arg is currentRoute.lookupTemplate()
        return "active"
  return ""

Template.registerHelper "currentUser", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  Meteor.user()

Template.registerHelper "login_message", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  "You must be logged in to see or add data."

Template.registerHelper "config", ->
  NeuronCatalogConfig.findOne({})

Template.registerHelper "binary_data_cursor", ->
  BinaryData.find {}

Template.registerHelper "get_all_tags", ->
  return Session.get("all_tags")

setTitle = () ->
  cfg = NeuronCatalogConfig.findOne {}
  if cfg?
    document.title = cfg.project_name
  else
    setTimeout(setTitle, 100)
  return

Meteor.startup ->
  Deps.autorun ->
    setTitle()
    return

  return
