import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import { get_collection_from_name } from '../lib/export_data'
import { Router } from '../lib/globals-lib'
import { DriverLines, NeuronTypes, BrainRegions, BinaryData, Schemas } from '../lib/model'

import { okCancelEvents } from './lib/globals'

var build_query_doc, del, update_url_bar

const comments_search_text = new ReactiveVar(null)

const flycircuit_search_text = new ReactiveVar(null)

const active_tags = new ReactiveVar({})

update_url_bar = function () {
  var cst, fst, q, taglist
  q = {}
  cst = comments_search_text.get()
  if (cst != null) {
    q['text'] = cst
  }
  fst = flycircuit_search_text.get()
  if (fst != null) {
    q['idid'] = fst
  }
  taglist = Object.keys(active_tags.get())
  if (taglist.length) {
    q['tags'] = JSON.stringify(taglist)
  }
  return Router.go('Search', {}, {
    query: q
  })
}

Template.Search.events(okCancelEvents('#comments-search-input', {
  ok: function (value, evt) {
    comments_search_text.set(value)
    update_url_bar()
  },
  cancel: function (evt) {
    comments_search_text.set(null)
    update_url_bar()
  }
}))

Template.Search.events(okCancelEvents('#flycircuit-search-input', {
  ok: function (value, evt) {
    flycircuit_search_text.set(value)
    update_url_bar()
  },
  cancel: function (evt) {
    flycircuit_search_text.set(null)
    update_url_bar()
  }
}))

Template.Search.events({
  'click .tag-name': function (event, template) {
    var myname, obj
    event.preventDefault()
    obj = active_tags.get()
    myname = this.name
    if (myname in obj) {
      delete obj[myname]
    } else {
      obj[myname] = true
    }
    active_tags.set(obj)
    return update_url_bar()
  }
})

del = function (obj, key) {
  var val
  val = obj[key]
  delete obj[key]
  return val
}

build_query_doc = function (orig) {
  var all_text_field_names, atl, atl_json, cst, data, doing_anything, fst, i, key, len, or_docs, orig_data, result, search_subdoc, search_subsubdoc, tfn
  orig_data = orig.query
  data = {}
  for (key in orig_data) {
    data[key] = orig_data[key]
  }
  result = {}
  doing_anything = false
  delete data['hash']
  cst = del(data, 'text')
  if (cst != null) {
    if (cst.length) {
      search_subsubdoc = {
        $regex: cst,
        $options: 'i'
      }
      all_text_field_names = ['comments.comment', 'name', 'synonyms']
      or_docs = []
      for (i = 0, len = all_text_field_names.length; i < len; i++) {
        tfn = all_text_field_names[i]
        search_subdoc = {}
        search_subdoc[tfn] = search_subsubdoc
        or_docs.push(search_subdoc)
      }
      result['$or'] = or_docs
      doing_anything = true
    }
  }
  fst = del(data, 'idid')
  if (fst != null) {
    if (fst === '*') {
      result.flycircuit_idids = {
        $exists: 1
      }
      result['$where'] = 'this.flycircuit_idids.length>=1'
    } else {
      fst = +fst
      result.flycircuit_idids = fst
    }
    doing_anything = true
  }
  atl_json = del(data, 'tags')
  if ((atl_json != null) && atl_json.length) {
    atl = JSON.parse(atl_json)
    result.tags = {
      $all: atl
    }
    doing_anything = true
  }
  if (!doing_anything) {
    return
  }
  if (Object.keys(data).length) {
    console.error('ERROR: unknown search parameters:', data)
  }
  return result
}

Template.Search.onRendered(function () {
  var atl, i, len, tag, taglist
  if (this.find('#comments-search-input') == null) {
    return
  }
  if (this.data.text != null) {
    comments_search_text.set(this.data.text)
  }
  if (this.data.idid != null) {
    flycircuit_search_text.set(this.data.idid)
  }
  if (this.data.tags != null) {
    atl = JSON.parse(this.data.tags)
    taglist = {}
    for (i = 0, len = atl.length; i < len; i++) {
      tag = atl[i]
      taglist[tag] = true
    }
    active_tags.set(taglist)
  }
  this.find('#comments-search-input').value = comments_search_text.get()
  const tmp = flycircuit_search_text.get()
  this.find('#flycircuit-search-input').value = tmp
  return tmp
})

Template.Search.helpers({
  current_search: function () {
    var query_doc
    query_doc = build_query_doc(this)
    if (query_doc != null) {
      return JSON.stringify(query_doc)
    }
  },
  driver_line_search_cursor: function () {
    var query_doc
    query_doc = build_query_doc(this)
    if (query_doc != null) {
      return DriverLines.find(query_doc)
    }
  },
  neuron_type_search_cursor: function () {
    var query_doc
    query_doc = build_query_doc(this)
    if (query_doc != null) {
      return NeuronTypes.find(query_doc)
    }
  },
  brain_region_search_cursor: function () {
    var query_doc
    query_doc = build_query_doc(this)
    if (query_doc != null) {
      return BrainRegions.find(query_doc)
    }
  },
  binary_data_search_cursor: function () {
    var query_doc
    query_doc = build_query_doc(this)
    if (query_doc != null) {
      return BinaryData.find(query_doc)
    }
  },
  get_tags: function () {
    var coll_name, coll_names_with_tags, collection, i, len, lods, my_active_tags, query_doc, result, tag_name, tmp, where_doc
    coll_names_with_tags = []
    for (coll_name in Schemas) {
      const keys = Schemas[coll_name].objectKeys()
      if (keys.indexOf('tags') >= 0) {
        coll_names_with_tags.push(coll_name)
      }
    }
    result = {}
    query_doc = {
      tags: {
        $exists: true
      }
    }
    where_doc = {
      tags: 1,
      _id: 0
    }
    for (i = 0, len = coll_names_with_tags.length; i < len; i++) {
      coll_name = coll_names_with_tags[i]
      collection = get_collection_from_name(coll_name)
      collection.find(query_doc, where_doc).forEach(function (doc) {
        var j, len1, ref, results, tag
        ref = doc.tags
        results = []
        for (j = 0, len1 = ref.length; j < len1; j++) {
          tag = ref[j]
          results.push(result[tag] = true)
        }
        return results
      })
    }
    lods = []
    my_active_tags = active_tags.get()
    for (tag_name in result) {
      tmp = {
        name: tag_name
      }
      if (tag_name in my_active_tags) {
        tmp.is_active_css_class = 'active'
      } else {
        tmp.is_active_css_class = ''
      }
      lods.push(tmp)
    }
    return lods
  }
})
