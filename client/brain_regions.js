import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'
import { $ } from './globals-client'

import { get_collection_from_name } from '../lib/export_data'
import { Deps, bootbox } from './globals-client'
import { NeuronTypes, BrainRegions } from '../lib/model'

import { get_sort_key, okCancelEvents, activateInput, renderTmp } from './lib/globals'

var brain_region_insert_callback
var editing_dao_id_var
var specialization_Dmel

specialization_Dmel = true

if (specialization_Dmel) {
  editing_dao_id_var = new ReactiveVar(null)
}

const driver_lines_sort = {}

driver_lines_sort[get_sort_key('DriverLines')] = 1

const neuron_types_sort = {}

neuron_types_sort[get_sort_key('NeuronTypes')] = 1

const brain_regions_sort = {}

brain_regions_sort[get_sort_key('BrainRegions')] = 1

Template.brain_region_from_id_block.helpers({
  brain_region_from_id: function () {
    var insert_types, my_id, my_types, result
    if ((typeof this === 'undefined' || this === null) || Object.keys(this).length === 0) {
      return
    }
    if (this.type != null) {
      my_id = this._id
      my_types = this.type
      insert_types = true
    } else {
      insert_types = false
      if (this._id != null) {
        return this
      }
      my_id = this
      if (this.valueOf) {
        my_id = this.valueOf()
      }
    }
    result = BrainRegions.findOne(my_id)
    if (result == null) {
      return
    }
    result.my_types = []
    if (insert_types) {
      result.my_types = my_types
    }
    return result
  }
})

brain_region_insert_callback = function (error, _id) {
  if (error != null) {
    bootbox.alert('Saving failed: ' + error)
    throw new Error('brain_region_insert_callback with error: ' + error)
  }
}

function save_brain_region (template) {
  var errors, name, result
  result = {}
  name = template.find('.name')[0].value
  errors = []
  if (name.length < 1) {
    errors.push('Name is required.')
  }
  if (errors.length > 0) {
    result.errors = errors
    return result
  }
  BrainRegions.insert({
    name: name,
    tags: [],
    comments: [],
    images: []
  }, brain_region_insert_callback)
  return result
}

Template.EditBrainRegionsDialog.helpers({
  brain_regions: function () {
    var collection, myself, result
    result = []
    collection = get_collection_from_name(this.collection_name)
    myself = collection.findOne({
      _id: this.my_id
    })
    BrainRegions.find({}, {
      sort: brain_regions_sort
    }).forEach(function (doc) {
      var i, len, ref, tmp
      doc.unspecific_is_checked = false
      doc.output_is_checked = false
      doc.input_is_checked = false
      ref = myself.brain_regions
      for (i = 0, len = ref.length; i < len; i++) {
        tmp = ref[i]
        if (tmp._id === doc._id) {
          if (tmp.type.indexOf('unspecified') >= 0) {
            doc.unspecific_is_checked = true
          }
          if (tmp.type.indexOf('output') >= 0) {
            doc.output_is_checked = true
          }
          if (tmp.type.indexOf('input') >= 0) {
            doc.input_is_checked = true
          }
        }
      }
      result.push(doc)
    })
    return result
  }
})

if (specialization_Dmel) {
  Template.brain_region_show.events(okCancelEvents('#edit-dao-input', {
    ok: function (value) {
      BrainRegions.update({
        _id: this._id
      }, {
        $set: {
          DAO_id: value
        }
      })
      return editing_dao_id_var.set(null)
    },
    cancel: function () {
      return editing_dao_id_var.set(null)
    }
  }))
  Template.brain_region_show.events({
    'click .insert-dao-id': function (event, template) {
      var element
      editing_dao_id_var.set(this._id)
      Deps.flush()
      element = template.find('#edit-dao-input')
      activateInput(element)
      if (this.DAO_id != null) {
        element.value = this.DAO_id
        return element.value
      }
    },
    'click .remove-dao-id': function (event) {
      var DAO_id, id
      DAO_id = this.DAO_id
      id = this._id
      return bootbox.confirm('Remove DAO ID "' + DAO_id + '"?', function (result) {
        if (result) {
          event.target.parentNode.style.opacity = 0
          return Meteor.setTimeout(function () {
            return BrainRegions.update({
              _id: id
            }, {
              $unset: {
                DAO_id: true
              }
            })
          }, 300)
        }
      })
    }
  })
  Template.brain_region_show.helpers({
    editing_dao_id: function () {
      return editing_dao_id_var.get()
    }
  })
}

Template.brain_region_show.helpers({
  driver_lines_referencing_me: function () {
    var DriverLines
    DriverLines = get_collection_from_name('DriverLines')
    return DriverLines.find({
      brain_regions: {
        $elemMatch: {
          _id: this._id
        }
      }
    })
  },
  neuron_types_referencing_me: function () {
    return NeuronTypes.find({
      brain_regions: {
        $elemMatch: {
          _id: this._id
        }
      }
    })
  }
})

Template.brain_region_table.helpers({
  showExpressionType: function (kw) {
    var data
    data = Template.parentData(kw.hash.parent)
    if (data.show_expression_type != null) {
      return data.show_expression_type
    } else {
      return true
    }
  },
  driver_lines_referencing_me: function () {
    var DriverLines
    DriverLines = get_collection_from_name('DriverLines')
    return DriverLines.find({
      brain_regions: {
        $elemMatch: {
          _id: this._id
        }
      }
    })
  },
  neuron_types_referencing_me: function () {
    return NeuronTypes.find({
      brain_regions: {
        $elemMatch: {
          _id: this._id
        }
      }
    })
  }
})

Template.brain_regions.events({
  'click .insert': function (event, template) {
    event.preventDefault()
    window.dialog_template = bootbox.dialog({
      title: 'Add a new brain region',
      message: renderTmp(Template.AddBrainRegionDialog),
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
            result = save_brain_region(dialog_template)
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

Template.brain_regions.helpers({
  brain_region_cursor: function () {
    return BrainRegions.find({}, {
      sort: brain_regions_sort
    })
  }
})

export function brain_region_fill_from_jquery (selector, template, brain_region_type, result) {
  var i, len, node, ref
  ref = template.find(selector)
  for (i = 0, len = ref.length; i < len; i++) {
    node = ref[i]
    if (node.checked) {
      if (!result.hasOwnProperty(node.id)) {
        result[node.id] = []
      }
      result[node.id].push(brain_region_type)
    }
  }
}

export function edit_brain_regions_save_func (template, coll_name, my_id) {
  var brain_regions, collection
  brain_regions = {}
  brain_region_fill_from_jquery('.brain_regions-unspecified', template, 'unspecified', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-output', template, 'output', brain_regions)
  brain_region_fill_from_jquery('.brain_regions-input', template, 'input', brain_regions)
  brain_regions = brain_region_dict2arr(brain_regions)
  collection = get_collection_from_name(coll_name)
  return collection.update(my_id, {
    $set: {
      brain_regions: brain_regions
    }
  })
}

export function brain_region_dict2arr (brain_regions) {
  var _id, result, tarr
  result = []
  for (_id in brain_regions) {
    tarr = brain_regions[_id]
    result.push({
      _id: _id,
      type: tarr
    })
  }
  return result
}
