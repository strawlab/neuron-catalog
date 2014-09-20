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

# --------------------------------------------
# session variables
Session.setDefault "editing_name", null
Session.setDefault "editing_add_synonym", null
Session.setDefault "modal_info", null
Session.setDefault "comment_preview_mode", false
Session.setDefault "comment_preview_html", null
window.modal_save_func = null

# --------------------------------------------
# helper functions
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

activateInput = (input) ->
  input.focus()
  input.select()
  return


# --------------------------------------------
Template.show_dialog.modal_info = ->
  tmp = Session.get("modal_info")
  tmp

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
      @save_driver_line info, template

    insert_template_name: "driver_line_insert"
    delete_template_name: "driver_line_show_brief"
    element_route: "driver_line_show"
    base_route: "driver_lines"
    edit_neuron_types_template_name: "edit_neuron_types"
    edit_neuropils_template_name: "edit_neuropils"

  NeuronTypes:
    remove: (x) ->
      remove_neuron_type x

    save: (info, template) ->
      @save_neuron_type info, template

    insert_template_name: "neuron_type_insert"
    delete_template_name: "neuron_type_show_brief"
    element_route: "neuron_type_show"
    base_route: "neuron_types"
    edit_driver_lines_template_name: "edit_driver_lines"
    edit_neuropils_template_name: "edit_neuropils"

  Neuropils:
    remove: (x) ->
      remove_neuropil x

    save: (info, template) ->
      @save_neuropil info, template

    insert_template_name: "neuropil_insert"
    delete_template_name: "neuropil_show_brief"
    element_route: "neuropil_show"
    base_route: "neuropils"

  BinaryData:
    remove: (x) ->
      remove_binary_data x

    delete_template_name: "binary_data_show_brief"
    base_route: "binary_data"

Template.name_field.editing_name = ->
  d = Session.get("editing_name")
  return false  unless d?
  return true  if @my_id is d.my_id & @collection is d.collection
  false

Template.name_field.events "click .edit-name": (e, tmpl) ->
  Session.set "editing_name", tmpl.data
  Deps.flush() # update DOM before focus
  ni = tmpl.find("#name_input")
  ni.value = @name
  activateInput ni
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
Template.delete_button.events "click .delete": (e) ->
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


# ------- tab layout stuff ----
Template.MyLayout.tab_attrs_home = ->
  current = Router.current()
  class: "active"  if current and current.route.name is "home"

Template.MyLayout.tab_attrs_driver_lines = ->
  cur = Router.current()
  class: "active"  if cur and cur.route.name is "driver_lines" or cur.route.name is "driver_line_show"

Template.MyLayout.tab_attrs_binary_data = ->
  cur = Router.current()
  class: "active"  if cur and cur.route.name is "binary_data" or cur.route.name is "binary_data_show"

Template.MyLayout.tab_attrs_neuron_types = ->
  cur = Router.current()
  class: "active"  if cur and cur.route.name is "neuron_types" or cur.route.name is "neuron_type_show"

Template.MyLayout.tab_attrs_neuropils = ->
  cur = Router.current()
  class: "active"  if cur and cur.route.name is "neuropils" or cur.route.name is "neuropil_show"
