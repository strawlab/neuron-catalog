window.get_sort_key = (collection_name) ->
  if collection_name is "DriverLines"
    sort_key = 'name'
  else if collection_name is "NeuronTypes"
    sort_key = 'name'
  else if collection_name is "BrainRegions"
    sort_key = 'name'
  else
    sort_key = '_id'
  sort_key

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
  document.body.appendChild(node)
  Blaze.renderWithData(template, data, node)
  node

window.specialization_Dmel = ->
  config = NeuronCatalogConfig.findOne({_id: 'config'})
  if !config
    return false
  if !config.NeuronCatalogSpecialization
    return false
  return "Drosophila melanogaster" == config.NeuronCatalogSpecialization

Template.registerHelper "specialization_Dmel", ->
  return window.specialization_Dmel()
