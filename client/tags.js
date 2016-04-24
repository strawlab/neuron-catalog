import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import { Deps, bootbox } from './globals-client'
import { get_collection_from_name } from '../lib/export_data'
import { okCancelEvents, activateInput } from './lib/globals'

var editing_add_tag

editing_add_tag = new ReactiveVar(null)

Template.tags_panel.events(okCancelEvents('#edit-tag-input', {
  ok: function (value) {
    var coll
    coll = get_collection_from_name(this.collection)
    coll.update(this._id, {
      $addToSet: {
        tags: value
      }
    })
    editing_add_tag.set(null)
  },
  cancel: function () {
    editing_add_tag.set(null)
  }
}))

Template.tags_panel.events({
  'click .add-tag': function (e, tmpl) {
    editing_add_tag.set(this._id)
    Deps.flush()
    activateInput(tmpl.find('#edit-tag-input'))
  },
  'click .remove': function (evt) {
    var coll, parent_id, tag
    tag = this.name
    parent_id = this.parent_id
    coll = get_collection_from_name(this.collection)
    return bootbox.confirm('Remove tag "' + tag + '"?', function (result) {
      if (result) {
        evt.target.parentNode.style.opacity = 0
        return Meteor.setTimeout(function () {
          return coll.update({
            _id: parent_id
          }, {
            $pull: {
              tags: tag
            }
          })
        }, 300)
      }
    })
  }
})

Template.tags_panel.helpers({
  adding_tag: function () {
    return editing_add_tag.get() === this._id
  },
  tag_dicts: function () {
    var i, len, name, ref, result, tmp
    result = []
    if (this.tags == null) {
      return result
    }
    ref = this.tags
    for (i = 0, len = ref.length; i < len; i++) {
      name = ref[i]
      tmp = {
        name: name,
        parent_id: this._id,
        collection: this.collection
      }
      result.push(tmp)
    }
    return result
  }
})
