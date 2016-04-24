import { Template } from 'meteor/templating'

import { get_collection_from_name, get_fileObj } from '../lib/export_data'
import { NeuronCatalogConfig } from '../lib/model'
import { bootbox, AutoForm } from './globals-client'

// The following line is needed for the quickForm template helper to find the
// collection "NeuronCatalogConfig".
window.NeuronCatalogConfig = NeuronCatalogConfig

function update_callback (error, result) {
  console.log('update complete')
  if ((typeof error !== 'undefined' && error !== null)) {
    console.error('update error:', error)
  }
  return console.log('update result:', result)
}

var check_doc = function (doc) {
  var coll = get_collection_from_name(this.name)
  var my_context = coll.simpleSchema().namedContext()
  my_context.validate(doc)
  var invalid_keys = my_context.invalidKeys()
  if (this.name === 'BinaryData') {
    console.log('checking archives for', doc._id)
    // check existance of files where they should exist.
    var fileObj = get_fileObj(doc, 'archive')
    if (!(typeof fileObj !== 'undefined' && fileObj !== null)) {
      console.error('for BinaryData doc', doc._id, 'archive', doc.archiveId, 'should exist, but it does not.')
    }

    if ((doc.cacheId != null)) {
      var fileObjCache = get_fileObj(doc, 'thumb')
      if (!(typeof fileObjCache !== 'undefined' && fileObjCache !== null)) {
        console.error('for BinaryData doc', doc._id, 'cache', doc.cacheId, 'should exist, but it does not.')
      }
    }

    if ((doc.thumbId != null)) {
      var fileObjThumb = get_fileObj(doc, 'thumb')
      if (!(typeof fileObjThumb !== 'undefined' && fileObjThumb !== null)) {
        console.error('for BinaryData doc', doc._id, 'thumb', doc.thumbId, 'should exist, but it does not.')
      }
    }
  }

  if (invalid_keys.length > 0) {
    console.log('for doc', doc)
    console.warn('invalid keys', invalid_keys)
    if (this.do_repair) {
      var modified = false
      var setter = {}
      for (var i = 0, el; i < invalid_keys.length; i++) {
        el = invalid_keys[i]
        if (el.type === 'required') {
          if (el.value === null) {
            if (el.name === 'tags') {
              setter[el.name] = []
              modified = true
            }
            if (el.name === 'comments') {
              setter[el.name] = []
              modified = true
            }
            if (el.name === 'images') {
              setter[el.name] = []
              modified = true
            }
            if (el.name === 'synonyms') {
              setter[el.name] = []
              modified = true
            }
            if (el.name === 'flycircuit_idids') {
              setter[el.name] = []
              modified = true
            }
          }
        }
      }
      if (modified) {
        var modifier = {}
        if ((typeof setter !== 'undefined' && setter !== null)) {
          modifier['$set'] = setter
        }
        console.log('calling update on ', this.name, doc._id, 'with', modifier)
        coll.update({_id: doc._id}, modifier, update_callback)
      }
    }
  }
  return
}

Template.config.events({
  ['click .validate-docs'] (event, template) {
    var button = event.currentTarget
    var name = button.dataset.collection.valueOf()
    var do_repair = Boolean(parseInt(button.dataset.repair.valueOf(), 10))
    var coll = get_collection_from_name(name)
    coll.find().forEach(check_doc,
      {name: name,
      do_repair: do_repair
    })
    console.log('all', name, 'documents checked')
    return
  }
})

Template.config.helpers({
  collection_names () {
    return ['DriverLines', 'NeuronTypes', 'BrainRegions', 'BinaryData']
  },

  config_doc () {
    return NeuronCatalogConfig.findOne({})
  }
})

AutoForm.hooks({configQuickForm:
  {onSuccess (operation, result, template) {
    return bootbox.alert('Saved configuration successfully.')
  },
  onError (operation, error, template) {
    console.error('error saving new configuration', error)
    return bootbox.alert('Error saving configuration.')
  }
  }})
