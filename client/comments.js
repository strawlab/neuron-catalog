import { Meteor } from 'meteor/meteor'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import { Showdown, html_sanitize } from './globals-client'
import { get_collection_from_name } from '../lib/export_data'

var comment_preview_html, comment_preview_mode, converter, on_delete_comment_callback, url_converter

comment_preview_mode = new ReactiveVar(false)

comment_preview_html = new ReactiveVar(null)

converter = new Showdown.converter() // eslint-disable-line new-cap

Template.comments_panel.helpers({
  comment_preview: function () {
    return comment_preview_html.get()
  },
  is_previewing_comment: function () {
    return comment_preview_mode.get() === true
  },
  is_writing_attrs: function () {
    if (comment_preview_mode.get()) {
      return 'vis-hidden'
    }
  },
  is_previewing_attrs: function () {
    if (comment_preview_mode.get() === false) {
      return 'vis-hidden'
    }
  }
})

Template.comments_panel.events({
  'click .write-comment': function (event, template) {
    event.preventDefault()
    comment_preview_mode.set(false)
    comment_preview_html.set(null)
  },
  'click .preview-comment': function (event, template) {
    var comments_raw, result, ta
    event.preventDefault()
    ta = template.find('textarea.comments')
    comments_raw = ta.value
    result = converter.makeHtml(comments_raw)
    comment_preview_mode.set(true)
    comment_preview_html.set(result)
  },
  'click .save': function (event, template) {
    var cdict, collection, comments_raw, ta
    event.preventDefault()
    ta = template.find('textarea.comments')
    comments_raw = ta.value
    ta.value = ''
    comment_preview_html.set(null)
    if (comments_raw === '') {
      return
    }
    collection = get_collection_from_name(this.show_name)
    cdict = {
      comment: comments_raw
    }
    collection.update(this._id, {
      $push: {
        comments: cdict
      }
    })
  }
})

url_converter = function (url) {
  return url
}

Template.show_comments.helpers({
  show_markdown: function (comment) {
    var untrustedCode
    untrustedCode = converter.makeHtml(comment.comment)
    return html_sanitize(untrustedCode, url_converter)
  },
  wrapped_comments: function () {
    var doc, i, result
    result = []
    for (i in this.comments) {
      doc = {}
      doc.comment = this.comments[i]
      doc.parent_show_name = this.show_name
      doc.parent_id = this._id
      result.push(doc)
    }
    return result
  }
})

on_delete_comment_callback = function (error) {
  if (error != null) {
    return console.error('Failure during remote call:', error)
  }
}

Template.show_comments.events({
  'click .delete': function (evt, tmpl) {
    return Meteor.call('delete_comment', {
      collection_name: this.parent_show_name,
      _id: this.parent_id,
      comment: this.comment
    }, on_delete_comment_callback)
  }
})
