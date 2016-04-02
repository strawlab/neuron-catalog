import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import { Deps, bootbox } from './globals-client'
import { okCancelEvents, activateInput } from './lib/globals'
import { get_collection_from_name } from '../lib/export_data'

const editing_flycircuit_idid = new ReactiveVar(null)

Template.FlyCircuitPanel.events(okCancelEvents('#edit-flycircuit-input', {
  ok: function (value) {
    var coll
    coll = get_collection_from_name(this.collection)
    coll.update(this._id, {
      $addToSet: {
        flycircuit_idids: +value
      }
    })
    editing_flycircuit_idid.set(null)
  },
  cancel: function () {
    editing_flycircuit_idid.set(null)
  }
}))

Template.FlyCircuitPanel.events({
  'click .add-flycircuit-idid': function (e, tmpl) {
    editing_flycircuit_idid.set(this._id)
    Deps.flush()
    activateInput(tmpl.find('#edit-flycircuit-input'))
  },
  'click .remove-flycircuit': function (evt) {
    var coll, flycircuit_idid, parent_id
    flycircuit_idid = this.name
    parent_id = this.parent_id
    coll = get_collection_from_name(this.collection)
    return bootbox.confirm('Remove flycircuit idid "' + flycircuit_idid + '"?', function (result) {
      if (result) {
        evt.target.parentNode.style.opacity = 0
        return Meteor.setTimeout(function () {
          return coll.update({
            _id: parent_id
          }, {
            $pull: {
              flycircuit_idids: flycircuit_idid
            }
          })
        }, 300)
      }
    })
  }
})

Template.FlyCircuitPanel.helpers({
  adding_flycircuit_idid: function () {
    return editing_flycircuit_idid.get() === this._id
  },
  idid_dicts: function () {
    var i, idid, len, ref, result, tmp
    result = []
    if (this.flycircuit_idids == null) {
      return result
    }
    ref = this.flycircuit_idids
    for (i = 0, len = ref.length; i < len; i++) {
      idid = ref[i]
      tmp = {
        name: idid,
        parent_id: this._id,
        collection: this.collection
      }
      result.push(tmp)
    }
    return result
  }
})
