import { Meteor } from 'meteor/meteor'
import { get_collection_from_name } from '../lib/export_data'

// server-side helper for client/comments.js
Meteor.methods({
  delete_comment: function (cfg) {
    const coll = get_collection_from_name(cfg.collection_name)
    const now = Date.now()
    const update_doc = {
      $pull: {
        comments: cfg.comment
      },
      $set: {
        last_edit_user: this.userId,
        last_edit_time: now
      }
    }
    return coll.update({
      _id: cfg._id
    }, update_doc, {
      validate: false,
      getAutoValues: false
    })
  }
})
