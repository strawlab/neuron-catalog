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
Session.setDefault "upload_processor_status", null

window.modal_save_func = null

# --------------------------------------------
# timer functions

update_upload_processor_status = ->
  if !Meteor.user()
    result =
      show_error: false
    Session.set("upload_processor_status",result)
    return

  doc = UploadProcessorStatus.findOne({'_id':'status'})

  if !doc?
    result =
      show_error: true
      message: "No status reported. (Ensure the binary upload processor is running on the server.)"
    Session.set("upload_processor_status",result)
    return

  now = Date.now()
  doc_time = new Date(doc.time)
  diff_msec = now-doc_time
  if diff_msec > 10000 # this value should be longer than sleep cycle duration on the server
    result =
      show_error: true
      message: "No binary processing is ongoing. Last status update is from "+moment(doc_time).fromNow()+"."
    Session.set("upload_processor_status",result)
    return
  result =
    show_error: false
  Session.set("upload_processor_status",result)
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
  else coll = BinaryData  if name is "BinaryData"
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


# --------------------------------------------

Template.raw_document_view.helpers
  raw_document: ->
    coll = window.get_collection_from_name(@collection)
    doc = coll.findOne({_id: @my_id})
    JSON.stringify doc, `undefined`, 2

Template.linkout.helpers
  path: ->
    window.get_route_from_name(@collection).path({_id:@my_id})
  name: ->
    @doc.name

Template.next_previous_button.helpers
  get_linkout: ->
    coll = window.get_collection_from_name(@collection)
    if @which=="next"
      op = "$gt"
      direction = 1
    else
      op = "$lt"
      direction = -1
      # assert @which=="previous"
    query = {}
    query["_id"] = {}
    query["_id"][op]=@my_id
    options = {'sort':{'_id':direction},limit:1}
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

Template.UploadProcessorStatus.helpers get_upload_processor_status: ->
  Session.get("upload_processor_status")

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

window.jump_table =
  DriverLines:
    remove: (x) ->
      remove_driver_line x

    save: (info, template) ->
      save_driver_line info, template

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

Template.name_field.helpers
  editing_name: ->
    d = Session.get("editing_name")
    return false  unless d?
    return true  if @my_id is d.my_id & @collection is d.collection
    false

Template.name_field.events "click .edit-name": (e, tmpl) ->
  Session.set "editing_name", tmpl.data
  Deps.flush() # update DOM before focus
  ni = tmpl.find("#name_input")
  ni.value = @name
  window.activateInput ni
  return

Template.name_field.events window.okCancelEvents("#name_input",
  ok: (value) ->
    coll = window.get_collection_from_name(@collection)
    coll.update @my_id,
      $set:
        name: value

    Session.set "editing_name", null
    return

  cancel: ->
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
    $("#show_dialog_id").modal "show"
    return

# -------------

Template.show_user_date.helpers
  pretty_username: ->
    doc = Meteor.users.findOne {_id:this.userId}
    if doc? and doc.emails? and doc.emails.length>0
      return doc.emails[0].address
    "userID "+this.userId

  pretty_time: ->
    timestamp = Date(this.time)
    moment(this.time).fromNow()

# -------------

Template.show_upload_progress.helpers
  files: ->
    S3.collection.find()

# ------- tab layout stuff ----
Template.MyLayout.helpers
  tab_attrs_home: ->
    current = Router.current()
    class: "active"  if current and current.route.name is "home"

  tab_attrs_driver_lines: ->
    cur = Router.current()
    class: "active"  if cur and cur.route.name is "driver_lines" or cur.route.name is "driver_line_show"

  tab_attrs_binary_data: ->
    cur = Router.current()
    class: "active"  if cur and cur.route.name is "binary_data" or cur.route.name is "binary_data_show"

  tab_attrs_neuron_types: ->
    cur = Router.current()
    class: "active"  if cur and cur.route.name is "neuron_types" or cur.route.name is "neuron_type_show"

  tab_attrs_neuropils: ->
    cur = Router.current()
    class: "active"  if cur and cur.route.name is "neuropils" or cur.route.name is "neuropil_show"

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

Template.registerHelper "currentUser", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  Meteor.user()

Template.registerHelper "login_message", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  "You must be logged in to see or add data."

Template.registerHelper "config", ->
  NeuronCatalogConfig.findOne({})

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
