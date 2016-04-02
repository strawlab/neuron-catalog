import { Blaze } from 'meteor/blaze'
import { Template } from 'meteor/templating'

import { NeuronCatalogConfig } from '../../lib/model'

export function get_sort_key (collection_name) {
  let sort_key
  if (collection_name === 'DriverLines') {
    sort_key = 'name'
  } else if (collection_name === 'NeuronTypes') {
    sort_key = 'name'
  } else if (collection_name === 'BrainRegions') {
    sort_key = 'name'
  } else {
    sort_key = '_id'
  }
  return sort_key
}

// --------------------------------------------
// from: meteor TODO app

// Returns an event map that handles the "escape" and "return" keys and
// "blur" events on a text input (given by selector) and interprets them
// as "ok" or "cancel".
export function okCancelEvents (selector, callbacks) {
  let ok = callbacks.ok || function () {}

  let cancel = callbacks.cancel || function () {}

  let events = {}
  events[`keyup ${selector}, keydown ${selector}, focusout ${selector}`] = function (evt) {
    if (evt.type === 'keydown' && evt.which === 27) {
      // escape = cancel
      cancel.call(this, evt)
    } else if (evt.type === 'keyup' && evt.which === 13 || evt.type === 'focusout') {
      // blur/return/enter = ok/submit if non-empty
      let value = String(evt.target.value || '')
      if (value) {
        ok.call(this, value, evt)
      } else {
        cancel.call(this, evt)
      }
    }
    return
  }

  return events
}

export function activateInput (input) {
  input.focus()
  input.select()
  return
}

export function renderTmp (template, data) {
  // see http://stackoverflow.com/a/26309004/1633026
  let node = document.createElement('div')
  document.body.appendChild(node)
  Blaze.renderWithData(template, data, node)
  return node
}

export function specialization_Dmel () {
  let config = NeuronCatalogConfig.findOne({_id: 'config'})
  if (!config) {
    return false
  }
  if (!config.NeuronCatalogSpecialization) {
    return false
  }
  return config.NeuronCatalogSpecialization === 'Drosophila melanogaster'
}

Template.registerHelper('specialization_Dmel', () => specialization_Dmel())
