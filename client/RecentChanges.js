import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'
import $ from 'jquery'

import { get_collection_from_name } from '../lib/export_data'

let recent_changes_n_days = new ReactiveVar(2)

Template.RecentChanges.helpers({
  last_n_days () {
    return recent_changes_n_days.get()
  }
})

Template.RecentChanges.events({
  ['input, change'] (e) {
    e.preventDefault()
    let n_days = $('#last_n_days_widget').val()
    return recent_changes_n_days.set(n_days)
  }
})

Template.ChangeList.helpers({
  wrapped_changes () {
    let result = []
    let collection = this.collname // create local variable
    let coll = get_collection_from_name(this.collname)
    let options = {'sort': {'last_edit_time': -1}} // ,'limit':10}

    let { last_n_days } = this

    let cur = new Date()
    let msec = last_n_days * 24 * 60 * 60 * 1000
    let past = cur - msec

    let query = {'last_edit_time': {'$gt': past}}
    coll.find(query, options).forEach(row => result.push({collection, my_id: row._id, doc: row}))
    return result
  }
})
