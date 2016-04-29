import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import $ from 'jquery'

import { get_collection_from_name } from '../lib/export_data'
import { DriverLines, NeuronTypes, BrainRegions } from '../lib/model'
import { brain_region_fill_from_jquery, edit_brain_regions_save_func, brain_region_dict2arr } from './brain_regions'
import { edit_neuron_types_save_func } from './neuron_types'
import { endsWith } from './general'
import { bootbox } from './globals-client'

import { get_sort_key, renderTmp, specialization_Dmel } from './lib/globals'

let driver_lines_sort = {}
driver_lines_sort[get_sort_key('DriverLines')] = 1
let neuron_types_sort = {}
neuron_types_sort[get_sort_key('NeuronTypes')] = 1
let brain_regions_sort = {}
brain_regions_sort[get_sort_key('BrainRegions')] = 1

let typed_name = new ReactiveVar(null)

// ---- Template.driver_line_from_id_block -------------

let enhance_driver_line_doc = function (doc) {
  if (!(doc != null)) {
    return
  }

  if (doc.is_vt_gal4_line != null) {
    // already performed this check
    return doc
  }

  // default values
  doc.is_vt_gal4_line = false
  doc.vdrc_url = null
  doc.brainbase_url = null

  doc.is_flylight_gal4_line = false
  doc.flylight_url = null

  doc.has_remote_links = false

  let name = doc.name.toLowerCase()

  if (specialization_Dmel()) {
    if (name.lastIndexOf('gmr', 0) === 0 && endsWith(name, 'gal4')) {
      doc.is_flylight_gal4_line = true
      const shortName = name.substring(2, 8) // without 'gm'
      doc.flylight_url = `https://strawlab.org/fly-enhancer-redirect/v1/flylight?line=${shortName}`
      doc.has_remote_links = true
    }

    if (name.lastIndexOf('vt', 0) === 0 && endsWith(name, 'gal4')) {
      doc.is_vt_gal4_line = true
      let vt_number_str = name.substring(2, name.length - 4)
      if (endsWith(vt_number_str, '-')) {
        vt_number_str = vt_number_str.substring(0, vt_number_str.length - 1)
      }
      const shortName = vt_number_str
      doc.vdrc_url = `https://strawlab.org/fly-enhancer-redirect/v1/vdrc?vt=${shortName}`
      doc.brainbase_url = `https://strawlab.org/fly-enhancer-redirect/v1/bbweb?vt=${shortName}`
      doc.has_remote_links = true
    }
  }

  return doc
}

Template.driver_line_from_id_block.helpers({
  driver_line_from_id () {
    if (this._id) {
      // already a doc
      return enhance_driver_line_doc(this)
    }
    let my_id = this
    if (this.valueOf) {
      // If we have "valueOf" function, "this" is boxed.
      my_id = this.valueOf() // unbox it
    }
    return enhance_driver_line_doc(DriverLines.findOne(my_id))
  }
})

// ---- Template.AddDriverLineDialog -------------

Template.AddDriverLineDialog.helpers({
  neuron_types () {
    return NeuronTypes.find({}, {sort: neuron_types_sort})
  },

  brain_regions () {
    return BrainRegions.find({}, {sort: brain_regions_sort})
  },

  count_cursor (cursor) {
    if ((cursor != null) && (cursor.count != null) && cursor.count() > 0) {
      return true
    }
    return false
  },

  matching_driver_lines () {
    let my_typed_name = typed_name.get()
    if (!(my_typed_name != null)) {
      return []
    }
    if (my_typed_name.length === 0) {
      return []
    }
    return DriverLines.find({name: {$regex: `^${my_typed_name}`, $options: 'i'}})
  },

  get_linkout () {
    return {collection: 'DriverLines', doc: this, my_id: this._id}
  }
})

Template.AddDriverLineDialog.events({
  ['keyup .driver-line-lookup'] (event, template) {
    return typed_name.set(template.find('.name').value)
  }
})

// ---- Template.EditDriverLinesDialog -------------

Template.EditDriverLinesDialog.helpers({
  driver_lines () {
    let result = []
    let collection = get_collection_from_name(this.collection_name)
    let myself = collection.findOne({_id: this.my_id})
    DriverLines.find({}, {sort: driver_lines_sort}).forEach(function (doc) {
      doc.is_checked = false
      if (myself.hasOwnProperty('best_driver_lines')) {
        if (myself.best_driver_lines.indexOf(doc._id) !== -1) {
          doc.is_checked = true
        }
      }
      result.push(doc)
      return
    })
    return result
  }
})

// ---- Template.driver_line_show -------------

Template.driver_line_show.events({
  ['click .edit-neuron-types'] (event, template) {
    event.preventDefault()
    let send_coll = 'DriverLines'
    let send_id = this._id
    let data = {
      collection_name: send_coll,
      my_id: send_id
    }

    window.dialog_template = bootbox.dialog({
      message: renderTmp(Template.EditNeuronTypesDialog, data),
      title: `Edit neuron types for driver line ${this.name}`,
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback () {
            let { dialog_template } = window
            return edit_neuron_types_save_func(dialog_template, send_coll, send_id)
          }
        }
      }
    })
    return window.dialog_template
  },

  ['click .edit-brain-regions'] (event, template) {
    event.preventDefault()
    let send_coll = 'DriverLines'
    let send_id = this._id
    let data = {
      collection_name: send_coll,
      my_id: send_id
    }
    window.dialog_template = bootbox.dialog({
      title: `Edit brain regions for driver line ${this.name}`,
      message: renderTmp(Template.EditBrainRegionsDialog, data),
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback () {
            let { dialog_template } = window
            return edit_brain_regions_save_func(dialog_template, send_coll, send_id)
          }
        }
      }
    })
    return window.dialog_template.on('submit', function () {
      window.dialog_template.find('.btn-primary').click()
      return false
    }
    )
  }
})

// ---- Template.driver_lines -------------

Template.driver_lines.helpers({
  driver_line_cursor () {
    return DriverLines.find({}, {sort: driver_lines_sort})
  }
})

Template.driver_lines.events({
  ['click .insert'] (event, template) {
    event.preventDefault()
    typed_name.set(null)
    window.dialog_template = bootbox.dialog({
      title: 'Add a new driver line',
      message: renderTmp(Template.AddDriverLineDialog),
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback () {
            let { dialog_template } = window
            let result = save_driver_line(dialog_template)
            if (result.errors) {
              return bootbox.alert(`Errors: ${result.errors.join(', ')}`)
            }
          }
        }
      }
    })

    window.dialog_template.on('shown.bs.modal', () => $('.name').focus()
    )
    return window.dialog_template.on('submit', function () {
      window.dialog_template.find('.btn-primary').click()
      return false
    }
    )
  }
})

// ------------- general functions --------

let driver_line_insert_callback = function (error, _id) {
  if (error != null) {
    console.error('driver_line_insert_callback with error:', error)
    bootbox.alert(`Saving failed: ${error}`)
  }
  return
}

// @remove_driver_line is defined in ../neuron-catalog.coffee

function save_driver_line (template) {
  let result = {}
  let doc = {}
  let errors = []

  // TODO check for duplicates

  // parse
  if (!(template.find != null)) {
    console.error('no template.find')
    return
  }
  doc.name = template.find('.name')[0].value
  if (doc.name.length < 1) {
    errors.push('Name is required.')
  }
  doc.neuron_types = []
  let r1 = template.find('.neuron_types')
  for (let i = 0; i < r1.length; i++) {
    let node = r1[i]
    if (node.checked) {
      doc.neuron_types.push(node.id)
    }
  }

  let brain_regions = {}
  brain_region_fill_from_jquery('.brain_regions-unspecified', template, 'unspecified', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-output', template, 'output', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-input', template, 'input', brain_regions)
  brain_regions = brain_region_dict2arr(brain_regions)

  doc.brain_regions = brain_regions
  doc.tags = []
  doc.images = []
  doc.comments = []
  doc.flycircuit_idids = []

  // report errors
  if (errors.length > 0) {
    result.errors = errors
    return result
  }

  // save result
  DriverLines.insert(doc, driver_line_insert_callback)
  return result
}

export function edit_driver_lines_save_func (template, coll_name, my_id) {
  let driver_lines = []
  let iterable = template.find('.driver_lines')
  for (let i = 0; i < iterable.length; i++) {
    let node = iterable[i]
    if (node.checked) {
      driver_lines.push(node.id)
    }
  }
  let collection = get_collection_from_name(coll_name)
  return collection.update(my_id, {
    $set: {
      best_driver_lines: driver_lines
    }
  })
}
