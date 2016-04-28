import { Meteor } from 'meteor/meteor'
import { Deps, moment, bootbox } from './globals-client'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'
import { Session } from 'meteor/session'
import $ from 'jquery'
import { Router, Roles } from '../lib/globals-lib'
import { get_collection_from_name } from '../lib/export_data'
import { isSandstorm, sandstormCheckRole, toUserSchema } from '../lib/init/sandstorm'
import { ReaderRoles, WriterRoles, BinaryData } from '../lib/model'
import { neuron_catalog_version } from '../lib/version'
import { make_safe, remove_driver_line, remove_neuron_type, remove_brain_region, remove_binary_data } from '../lib/routes'

import { get_sort_key, activateInput, okCancelEvents, renderTmp } from './lib/globals'

// -------------
// font awesome (see
// https://github.com/nate-strauser/meteor-font-awesome/blob/master/load.js )
let head = document.getElementsByTagName('head')[0]

// Generate a style tag
let style = document.createElement('link')
style.type = 'text/css'
style.rel = 'stylesheet'
style.href = '/css/font-awesome.min.css'
head.appendChild(style)

Meteor.subscribe('driver_lines')
Meteor.subscribe('neuron_types')
Meteor.subscribe('brain_regions')
Meteor.subscribe('binary_data')
Meteor.subscribe('neuron_catalog_config')
Meteor.subscribe('settings_to_client')
Meteor.subscribe('userData')
Meteor.subscribe('archive_filestore')
Meteor.subscribe('cache_filestore')
Meteor.subscribe('upload_temp_filestore')

// --------------------------------------------
// session variables
let editing_name = new ReactiveVar(null)

let DEFAULT_TITLE = 'neuron catalog'
Session.setDefault('DocumentTitle', DEFAULT_TITLE)

// --------------------------------------------
// helper functions

function currentUser () {
  let result
  if (isSandstorm()) {
    result = toUserSchema(Meteor.sandstormUser())
  } else {
    result = Meteor.user()
  }
  return result
}

export function checkRoleClient (roles) {
  if (isSandstorm()) {
    return sandstormCheckRole(currentUser(), roles)
  } else {
    return Roles.userIsInRole(currentUser(), roles)
  }
}

export function endsWith (str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1
}

export function utf8_to_b64 (str) {
  return window.btoa(unescape(encodeURIComponent(str)))
}

export function b64_to_utf8 (str) {
  return decodeURIComponent(escape(window.atob(str)))
}

function get_route_from_name (name) {
  let route
  if (name === 'DriverLines') {
    route = Router.routes['driver_line_show']
  } else if (name === 'NeuronTypes') {
    route = Router.routes['neuron_type_show']
  } else if (name === 'BrainRegions') {
    route = Router.routes['brain_region_show']
  } else {
    if (name === 'BinaryData') {
      route = Router.routes['binary_data_show']
    }
  }
  return route
}

// --------------------------------------------

Template.RawDocumentView.helpers({
  raw_document () {
    if (isSandstorm() && this.collection === 'Meteor.users') {
      return JSON.stringify(toUserSchema(Meteor.sandstormUser()))
    }
    let coll = get_collection_from_name(this.collection)
    let doc = coll.findOne({_id: this.my_id})
    return JSON.stringify(doc, undefined, 2)
  }
})

Template.linkout.helpers({
  path () {
    let coll = get_collection_from_name(this.collection)
    let doc = coll.findOne({_id: this.my_id})
    return get_route_from_name(this.collection).path(doc)
  },
  name () {
    return this.doc.name
  }
})

Template.next_previous_button.helpers({
  get_linkout () {
    let coll = get_collection_from_name(this.collection)
    let my_doc = coll.findOne({_id: this.my_id})
    if (!(my_doc != null)) {
      return
    }
    let op
    let direction
    if (this.which === 'next') {
      op = '$gt'
      direction = 1
    } else {
      op = '$lt'
      direction = -1
    }
    // assert @which=="previous"

    // Did I mention how much I do not understand how JavaScript and
    // Coffeescript automatically quote string literals unless using
    // square brackets?
    let sort_key = get_sort_key(this.collection)
    let query = {}
    query[sort_key] = {}
    query[sort_key][op] = my_doc[sort_key]
    let sort_options = {}
    sort_options[sort_key] = direction
    let options = {limit: 1}
    options['sort'] = sort_options
    let cursor = coll.find(query, options)
    if (cursor.count() === 0) {
      return
    }
    let arr = cursor.fetch()
    let doc = arr[0]
    let result = {}
    result['collection'] = this.collection
    result['my_id'] = doc['_id']
    result['doc'] = doc
    return result
  }
})

const jump_table = {
  DriverLines: {
    remove: function (x) {
      return remove_driver_line(x)
    },
    delete_template_name: 'driver_line_show_brief',
    base_route: 'driver_lines'
  },
  NeuronTypes: {
    remove: function (x) {
      return remove_neuron_type(x)
    },
    delete_template_name: 'neuron_type_show_brief',
    base_route: 'neuron_types'
  },
  BrainRegions: {
    remove: function (x) {
      return remove_brain_region(x)
    },
    delete_template_name: 'brain_region_show_brief',
    base_route: 'brain_regions'
  },
  BinaryData: {
    remove: function (x) {
      return remove_binary_data(x)
    },
    delete_template_name: 'binary_data_show_brief',
    base_route: 'binary_data'
  }
}

Template.top_content_row2.helpers({
  editing_name: function () {
    var d
    d = editing_name.get()
    if (d == null) {
      return false
    }
    if (this._id === d._id & this.collection === d.collection) {
      return true
    }
    return false
  }
})

Template.top_content_row2.events({
  'click .edit-name': function (e, tmpl) {
    var ni
    editing_name.set(tmpl.data)
    Deps.flush()
    ni = tmpl.find('#name-input')
    ni.value = this.name
    activateInput(ni)
  }
})

Template.top_content_row2.events(okCancelEvents('#name-input', {
  ok (value, evt) {
    if (editing_name.get() === null) {
      // Hmm, why do we get here? Cancel was clicked.
      return
    }
    let coll = get_collection_from_name(this.collection)
    coll.update(this._id, {
      $set: {
        name: value
      }
    })

    editing_name.set(null)
    return
  },

  cancel (evt) {
    editing_name.set(null)
    return
  }
}
))

Template.delete_button.events({
  ['click .delete'] (e) {
    e.preventDefault()

    let my_info = jump_table[this.collection]
    let data = {
      body_template_name: my_info.delete_template_name,
      body_template_data: this.my_id
    }
    let { my_id } = this

    window.dialog_template = bootbox.dialog({
      message: renderTmp(Template.DeleteDialog, data),
      title: 'Do you want to delete this?',
      buttons: {
        close: {
          label: 'Close'
        },
        delete: {
          label: 'Delete',
          className: 'btn-danger',
          callback () {
            my_info.remove(my_id)
            let route_name = my_info.base_route
            return Router.go(route_name)
          }
        }
      }
    })
    return window.dialog_template
  }
})

// -------------

Template.raw_button.events({
  ['click .raw'] (event, template) {
    event.preventDefault()
    let data = {
      collection: this.collection,
      my_id: this.my_id
    }
    window.dialog_template = bootbox.dialog({
      message: renderTmp(Template.RawDocumentView, data),
      title: 'Raw document view',
      buttons: {
        close: {
          label: 'Close'
        }
      }
    })
    return window.dialog_template.off('shown.bs.modal') // do not focus on button
  }
})

// -------------

export function append_spinner (div) {
  return $(div).html('Loading...')
}

// -------------

Template.show_user_date.helpers({
  pretty_username () {
    let doc = Meteor.users.findOne({_id: this.userId})
    if ((doc != null) && (doc.profile != null) && (doc.profile.name != null)) {
      return doc.profile.name
    }
    return `userID ${this.userId}`
  },

  pretty_time () {
    return moment(this.time).fromNow()
  }
})

// --------

Template.registerHelper('rtfd', function () {
  return {
    base_url: 'https://neuron-catalog.readthedocs.org',
    language: 'en',
    version: 'latest'
  }
})

Template.registerHelper('neuron_catalog_version', () => neuron_catalog_version)

Template.registerHelper('get_brain_regions', function (doc, type) {
  let result = []
  for (let i = 0; i < doc.brain_regions.length; i++) {
    let brain_region = doc.brain_regions[i]
    if (__in__(type, brain_region.type)) {
      result.push(brain_region)
    }
  }
  return result
})

Template.registerHelper('activeIfTemplateIn', function () {
  let currentRoute = Router.current()
  if (!(currentRoute != null)) {
    return ''
  }
  if (!(currentRoute.route != null)) {
    return ''
  }
  for (let i = 0; i < arguments.length; i++) {
    let arg = arguments[i]
    if (arg === currentRoute.lookupTemplate()) {
      return 'active'
    }
  }
})

// Mimic the normal meteor accounts system from IronRouter template.
Template.registerHelper('currentUser', () => currentUser())

Template.registerHelper('binary_data_cursor', () => BinaryData.find({}))

Template.registerHelper('isInReaderRole', () => checkRoleClient(ReaderRoles))

Template.registerHelper('isInWriterRole', () => checkRoleClient(WriterRoles))

Template.registerHelper('pathForName', function (routeName) {
  let route = Router.routes[routeName]
  return route.path({_id: this._id, name: make_safe(this.name)})
})

Template.registerHelper('isSandstorm', () => isSandstorm())

Template.registerHelper('hasPermission', permissionName => checkRoleClient([permissionName]))

Template.registerHelper('defaultTitle', () => DEFAULT_TITLE)

Deps.autorun(() => document.title = Session.get('DocumentTitle'))

function __in__ (needle, haystack) {
  return haystack.indexOf(needle) >= 0
}
