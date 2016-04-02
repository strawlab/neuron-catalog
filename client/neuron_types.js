import { Meteor } from 'meteor/meteor'
import { Template } from 'meteor/templating'
import { ReactiveVar } from 'meteor/reactive-var'

import $ from 'jquery'

import { Deps, bootbox } from './globals-client'

import { get_collection_from_name } from '../lib/export_data'
import { brain_region_fill_from_jquery, edit_brain_regions_save_func, brain_region_dict2arr } from './brain_regions'
import { edit_driver_lines_save_func } from './driver_lines'
import { DriverLines, NeuronTypes, BrainRegions } from '../lib/model'

import { get_sort_key, okCancelEvents, activateInput, renderTmp } from './lib/globals'

var brain_regions_sort, driver_lines_sort, editing_add_synonym, neuron_type_insert_callback, neuron_types_sort

editing_add_synonym = new ReactiveVar(null)

driver_lines_sort = {}

driver_lines_sort[get_sort_key('DriverLines')] = 1

neuron_types_sort = {}

neuron_types_sort[get_sort_key('NeuronTypes')] = 1

brain_regions_sort = {}

brain_regions_sort[get_sort_key('BrainRegions')] = 1

Template.neuron_type_from_id_block.helpers({
  neuron_type_from_id: function () {
    var my_id
    if (this._id) {
      return this
    }
    my_id = this
    if (this.valueOf) {
      my_id = this.valueOf()
    }
    return NeuronTypes.findOne(my_id)
  }
})

Template.AddNeuronTypeDialog.helpers({
  driver_lines: function () {
    return DriverLines.find({}, {
      'sort': driver_lines_sort
    })
  },
  brain_regions: function () {
    return BrainRegions.find({}, {
      'sort': brain_regions_sort
    })
  }
})

neuron_type_insert_callback = function (error, _id) {
  if (error != null) {
    console.error('neuron_type_insert_callback with error:', error)
    bootbox.alert('Saving failed: ' + error)
  }
}

function save_neuron_type (template) {
  var brain_regions, doc, errors, result
  result = {}
  doc = {}
  errors = []
  if (template.find == null) {
    console.error('no template.find')
    return
  }
  doc.name = template.find('.name')[0].value
  if (doc.name.length < 1) {
    errors.push('Name is required.')
  }
  doc.best_driver_lines = []
  brain_regions = {}
  brain_region_fill_from_jquery('.brain_regions-unspecified', template, 'unspecified', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-output', template, 'output', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-input', template, 'input', brain_regions)
  brain_regions = brain_region_dict2arr(brain_regions)
  doc.brain_regions = brain_regions
  doc.tags = []
  doc.comments = []
  doc.images = []
  doc.synonyms = []
  doc.flycircuit_idids = []
  if (errors.length > 0) {
    result.errors = errors
    return result
  }
  NeuronTypes.insert(doc, neuron_type_insert_callback)
  return result
}

Template.EditNeuronTypesDialog.helpers({
  neuron_types: function () {
    var collection, myself, result
    result = []
    collection = get_collection_from_name(this.collection_name)
    myself = collection.findOne({
      _id: this.my_id
    })
    NeuronTypes.find({}, {
      sort: neuron_types_sort
    }).forEach(function (doc) {
      if (myself.neuron_types.indexOf(doc._id) === -1) {
        doc.is_checked = false
      } else {
        doc.is_checked = true
      }
      result.push(doc)
    })
    return result
  }
})

Template.neuron_type_show.events(okCancelEvents('#edit_synonym_input', {
  ok: function (value) {
    NeuronTypes.update(this._id, {
      $addToSet: {
        synonyms: value
      }
    })
    editing_add_synonym.set(null)
  },
  cancel: function () {
    editing_add_synonym.set(null)
  }
}))

Template.neuron_type_show.events({
  'click .add_synonym': function (e, tmpl) {
    editing_add_synonym.set(this._id)
    Deps.flush()
    activateInput(tmpl.find('#edit_synonym_input'))
  },
  'click .remove-synonym': function (evt) {
    var id, synonym
    synonym = this.name
    id = this._id
    return bootbox.confirm('Remove synonym "' + synonym + '"?', function (result) {
      if (result) {
        evt.target.parentNode.style.opacity = 0
        return Meteor.setTimeout(function () {
          return NeuronTypes.update({
            _id: id
          }, {
            $pull: {
              synonyms: synonym
            }
          })
        }, 300)
      }
    })
  },
  'click .edit-best-driver-lines': function (event, template) {
    var data, send_coll, send_id
    event.preventDefault()
    send_coll = 'NeuronTypes'
    send_id = this._id
    data = {
      collection_name: send_coll,
      my_id: send_id
    }
    window.dialog_template = bootbox.dialog({
      title: 'Edit best driver lines for neuron type ' + this.name,
      message: renderTmp(Template.EditDriverLinesDialog, data),
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback: function () {
            var dialog_template
            dialog_template = window.dialog_template
            return edit_driver_lines_save_func(dialog_template, send_coll, send_id)
          }
        }
      }
    })
    return window.dialog_template
  },
  'click .edit-brain-regions': function (event, template) {
    var data, send_coll, send_id
    event.preventDefault()
    send_coll = 'NeuronTypes'
    send_id = this._id
    data = {
      collection_name: send_coll,
      my_id: send_id
    }
    window.dialog_template = bootbox.dialog({
      title: 'Edit brain regions for neuron type ' + this.name,
      message: renderTmp(Template.EditBrainRegionsDialog, data),
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback: function () {
            var dialog_template
            dialog_template = window.dialog_template
            return edit_brain_regions_save_func(dialog_template, send_coll, send_id)
          }
        }
      }
    })
    return window.dialog_template
  }
})

Template.neuron_type_show.helpers({
  adding_synonym: function () {
    return editing_add_synonym.get() === this._id
  },
  synonym_dicts: function () {
    var i, result, tmp
    result = []
    for (i in this.synonyms) {
      tmp = {
        name: this.synonyms[i],
        _id: this._id
      }
      result.push(tmp)
    }
    return result
  },
  driver_lines_referencing_me: function () {
    return DriverLines.find({
      neuron_types: this._id
    })
  }
})

Template.neuron_types.events({
  'click .insert': function (event, template) {
    event.preventDefault()
    window.dialog_template = bootbox.dialog({
      title: 'Add a new neuron type',
      message: renderTmp(Template.AddNeuronTypeDialog),
      buttons: {
        close: {
          label: 'Close'
        },
        save: {
          label: 'Save',
          className: 'btn-primary',
          callback: function () {
            var dialog_template, result
            dialog_template = window.dialog_template
            result = save_neuron_type(dialog_template)
            if (result.errors) {
              return bootbox.alert('Errors: ' + result.errors.join(', '))
            }
          }
        }
      }
    })
    window.dialog_template.on('shown.bs.modal', function () {
      return $('.name').focus()
    })
    return window.dialog_template.on('submit', function () {
      window.dialog_template.find('.btn-primary').click()
      return false
    })
  }
})

Template.neuron_types.helpers({
  neuron_type_cursor: function () {
    return NeuronTypes.find({}, {
      sort: neuron_types_sort
    })
  }
})

export function edit_neuron_types_save_func (template, coll_name, my_id) {
  var collection, i, len, neuron_types, node, ref
  neuron_types = []
  ref = template.find('.neuron_types')
  for (i = 0, len = ref.length; i < len; i++) {
    node = ref[i]
    if (node.checked) {
      neuron_types.push(node.id)
    }
  }
  collection = get_collection_from_name(coll_name)
  return collection.update(my_id, {
    $set: {
      neuron_types: neuron_types
    }
  })
}
