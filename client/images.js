import { Session } from 'meteor/session'
import { Template } from 'meteor/templating'
import { Tracker } from 'meteor/tracker'
import { Blaze } from 'meteor/blaze'
import { ReactiveVar } from 'meteor/reactive-var'

import { get_collection_from_name, get_fileObj } from '../lib/export_data'

import { BinaryData, ArchiveFileStore, CacheFileStore, ZipFileStore } from '../lib/model'

import $ from 'jquery'

import { renderTmp } from './lib/globals'
import { Deps, bootbox, Blob, File, FileReader, Tiff } from './globals-client'
import { append_spinner } from './general'

var DEFAULT_THUMB_HEIGHT, DEFAULT_THUMB_WIDTH, getThumbnail, get_blob, handle_file_step_two, handle_files, insert_image_save_func, link_image_save_func, on_link_image_dialog_shown, removeExtension, trigger_update, update_selected

trigger_update = new Deps.Dependency()

window.image_upload_template = null

DEFAULT_THUMB_WIDTH = 200

DEFAULT_THUMB_HEIGHT = 200

Session.setDefault('OngoingUploadFilesArchive', {})

Session.setDefault('OngoingUploadFilesCache', {})

Template.binary_data_from_id_block.helpers({
  get_doc: function (_id) {
    return BinaryData.findOne(_id)
  }
})

Template.binary_data_show.helpers({
  binary_data_type: function () {
    return this.type.slice(0, -1)
  },
  find_references: function () {
    var coll, coll_types, collname, image_id, j, len1, query, result
    coll_types = ['DriverLines', 'NeuronTypes', 'BrainRegions']
    image_id = this._id
    query = {
      images: image_id
    }
    result = []
    for (j = 0, len1 = coll_types.length; j < len1; j++) {
      collname = coll_types[j]
      coll = get_collection_from_name(collname)
      coll.find(query).forEach(function (doc) {
        return result.push({
          'collection': collname,
          'doc': doc,
          'my_id': doc._id
        })
      })
    }
    return result
  },
  fileObjArchive: function () {
    return get_fileObj(this, 'archive')
  },
  fileObjCache: function () {
    return get_fileObj(this, 'cache')
  }
})

link_image_save_func = function (template, collection_name, my_id) {
  var coll, elements, item, j, len1, myarr, t2
  coll = get_collection_from_name(collection_name)
  elements = template.find('.selected')
  myarr = []
  for (j = 0, len1 = elements.length; j < len1; j++) {
    item = elements[j]
    myarr.push(item.id)
  }
  t2 = {
    images: myarr
  }
  return coll.update(my_id, {
    $set: t2
  })
}

export function close_upload_dialog_if_no_more_uploads () {
  var count
  count = Object.keys(Session.get('OngoingUploadFilesArchive')).length + Object.keys(Session.get('OngoingUploadFilesCache')).length + Object.keys(Session.get('OngoingUploadFilesZip')).length
  if (count === 0) {
    return bootbox.hideAll()
  }
}

insert_image_save_func = function (template, coll_name, my_id, field_name) {
  var payload, upload_file
  payload = template.payload_var.get()
  if (payload == null) {
    return
  }
  upload_file = payload.original_file
  if (upload_file == null) {
    return
  }
  bootbox.dialog({
    message: renderTmp(Template.UploadProgress),
    title: 'Upload Progress'
  })
  return ArchiveFileStore.insert(upload_file, function (error, fileObj) {
    var newBinaryDataDoc, tmp
    if (error != null) {
      console.error(error)
      bootbox.alert('There was an error uploading the file')
      return
    }
    tmp = Session.get('OngoingUploadFilesArchive')
    tmp[fileObj._id] = true
    Session.set('OngoingUploadFilesArchive', tmp)
    fileObj.once('uploaded', function () {
      tmp = Session.get('OngoingUploadFilesArchive')
      delete tmp[fileObj._id]
      Session.set('OngoingUploadFilesArchive', tmp)
      return close_upload_dialog_if_no_more_uploads()
    })
    newBinaryDataDoc = {
      archiveId: fileObj._id,
      name: upload_file.name,
      lastModifiedDate: upload_file.lastModifiedDate,
      type: 'images',
      tags: [],
      comments: []
    }
    return BinaryData.insert(newBinaryDataDoc, function (error, newBinaryDataDocId) {
      var coll, myarr, orig, t2
      if (error != null) {
        console.error(error)
        bootbox.alert('There was an error saving upload results')
        return
      }
      if (coll_name != null) {
        coll = get_collection_from_name(coll_name)
        orig = coll.findOne({
          _id: my_id
        })
        myarr = []
        if (orig.hasOwnProperty(field_name)) {
          myarr = orig[field_name]
        }
        myarr.push(newBinaryDataDocId)
        t2 = {}
        t2[field_name] = myarr
        coll.update(my_id, {
          $set: t2
        })
      }
      if (payload.full_image != null) {
        CacheFileStore.insert(payload.full_image.file, function (error, fullCacheFileObj) {
          var updater_doc
          if (error) {
            console.error('full cache image upload error', error)
            return
          }
          updater_doc = {
            $set: {
              cacheId: fullCacheFileObj._id,
              cache_width: payload.full_image.width,
              cache_height: payload.full_image.height
            }
          }
          BinaryData.update(newBinaryDataDocId, updater_doc)
          tmp = Session.get('OngoingUploadFilesCache')
          tmp[fullCacheFileObj._id] = true
          Session.set('OngoingUploadFilesCache', tmp)
          return fullCacheFileObj.once('uploaded', function () {
            tmp = Session.get('OngoingUploadFilesCache')
            delete tmp[fullCacheFileObj._id]
            Session.set('OngoingUploadFilesCache', tmp)
            return close_upload_dialog_if_no_more_uploads()
          })
        })
      }
      if (payload.thumb != null) {
        return CacheFileStore.insert(payload.thumb.file, function (error, thumbFileObj) {
          var updater_doc
          if (error) {
            console.error('thumb upload error', error)
            return
          }
          updater_doc = {
            $set: {
              thumbId: thumbFileObj._id,
              thumb_width: payload.thumb.width,
              thumb_height: payload.thumb.height
            }
          }
          BinaryData.update(newBinaryDataDocId, updater_doc)
          tmp = Session.get('OngoingUploadFilesCache')
          tmp[thumbFileObj._id] = true
          Session.set('OngoingUploadFilesCache', tmp)
          return thumbFileObj.once('uploaded', function () {
            tmp = Session.get('OngoingUploadFilesCache')
            delete tmp[thumbFileObj._id]
            Session.set('OngoingUploadFilesCache', tmp)
            return close_upload_dialog_if_no_more_uploads()
          })
        })
      }
    })
  })
}

Template.AddImageCode2.events({
  'click .edit-images': function (event, template) {
    var coll, current_images, data, doc, send_coll, send_id
    event.preventDefault()
    coll = get_collection_from_name(this.collection)
    doc = coll.findOne({
      _id: this.my_id
    })
    if ((doc != null) && (doc.images != null)) {
      current_images = doc.images
    } else {
      current_images = []
    }
    send_coll = this.collection
    send_id = this.my_id
    data = {
      my_id: send_id,
      collection_name: send_coll,
      current_images: current_images
    }
    window.dialog_template = bootbox.dialog({
      message: renderTmp(Template.LinkExistingImageDialog, data),
      title: 'Link existing image or volume',
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
            return link_image_save_func(dialog_template, send_coll, send_id)
          }
        }
      }
    })
    return window.dialog_template.on('shown.bs.modal', function () {
      return on_link_image_dialog_shown(data)
    })
  }
})

Template.add_image_code.events({
  'click .insert': function (event, template) {
    var full_data, my_id, send_coll
    event.preventDefault()
    send_coll = this.collection
    my_id = this.my_id
    full_data = {
      title: 'Insert image or volume',
      body_template: Template.InsertImageDialog,
      body_data: null,
      save_label: 'Upload',
      render_complete: function (parent_template) {
        var body_template
        body_template = window.image_upload_template
        Tracker.autorun(function () {
          var jq_button, upload_ready
          upload_ready = body_template.upload_ready.get()
          jq_button = parent_template.$('#modal-dialog-save')
          if (upload_ready) {
            return jq_button.removeClass('disabled')
          } else {
            return jq_button.addClass('disabled')
          }
        })
        return parent_template.$('#modal-dialog-save').on('click', function (event) {
          template = window.image_upload_template
          if (template == null) {
            return
          }
          return insert_image_save_func(template, send_coll, my_id, 'images')
        })
      }
    }
    return Blaze.renderWithData(Template.ModalDialog, full_data, document.body)
  }
})

getThumbnail = function (original, width, height) {
  var canvas
  canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  canvas.getContext('2d').drawImage(original, 0, 0, canvas.width, canvas.height)
  return canvas
}

get_blob = function (canvas, type, quality) {
  var arr, binStr, i, len, result
  binStr = window.atob(canvas.toDataURL(type, quality).split(',')[1])
  len = binStr.length
  arr = new Uint8Array(len)
  i = 0
  while (i < len) {
    arr[i] = binStr.charCodeAt(i)
    i++
  }
  result = new Blob([arr], {
    type: type || 'image/png'
  })
  return result
}

removeExtension = function (filename) {
  var lastDotPosition
  lastDotPosition = filename.lastIndexOf('.')
  if (lastDotPosition === -1) {
    return filename
  } else {
    return filename.substr(0, lastDotPosition)
  }
}

handle_file_step_two = function (chosen_file, template, opts) {
  var actual_height, actual_width, blob, canvas, ctx, div, file, fname, max_height, max_width, orig_aspect, payload, scale, shortname, target_aspect, thumb_canvas
  opts = opts || {}
  payload = {}
  payload.original_file = chosen_file
  if (opts.full_image != null) {
    shortname = removeExtension(chosen_file.name)
    if (opts.preserve_full_image) {
      canvas = document.createElement('canvas')
      canvas.width = opts.full_image.width
      canvas.height = opts.full_image.height
      ctx = canvas.getContext('2d')
      ctx.drawImage(opts.full_image, 0, 0, canvas.width, canvas.height)
      blob = get_blob(canvas, 'image/jpeg', 0.8)
      fname = shortname + '.jpg'
      file = new File([blob], fname)
      payload.full_image = {
        file: file,
        width: canvas.width,
        height: canvas.height
      }
    }
    max_width = DEFAULT_THUMB_WIDTH
    max_height = DEFAULT_THUMB_HEIGHT
    orig_aspect = opts.full_image.width / opts.full_image.height
    target_aspect = max_width / max_height
    if (orig_aspect >= target_aspect) {
      actual_width = max_width
      scale = max_width / opts.full_image.width
      actual_height = Math.floor(opts.full_image.height * scale)
    } else {
      actual_height = max_height
      scale = max_height / opts.full_image.height
      actual_width = Math.floor(opts.full_image.width * scale)
    }
    thumb_canvas = getThumbnail(opts.full_image, actual_width, actual_height)
    blob = get_blob(thumb_canvas, 'image/jpeg', 0.8)
    fname = 'thumb-' + shortname + '.jpg'
    file = new File([blob], fname)
    payload.thumb = {
      file: file,
      width: actual_width,
      height: actual_height
    }
    div = template.find('#preview')
    $(div).empty()
    div.appendChild(thumb_canvas)
  } else {
    div = template.find('#preview')
    $(div).empty()
    $(div).html('No preview possible.')
  }
  template.payload_var.set(payload)
  return template.upload_ready.set(true)
}

handle_files = function (fileList, template) {
  var chosen_file, div, imageType, img, img_reader, tiff_reader
  if (fileList.length === 0) {
    div = template.find('#preview')
    $(div).empty()
    return
  }
  if (fileList.length > 1) {
    div = template.find('#preview')
    $(div).empty()
    console.error('More than one file selected')
    return
  }
  chosen_file = fileList[0]
  if (chosen_file.type === 'image/tiff') {
    tiff_reader = new FileReader()
    tiff_reader.onload = (function (theFile) {
      return function (e) {
        var dataUrl, exception, full_data, img, tiff
        try {
          Tiff.initialize({
            TOTAL_MEMORY: theFile.size * 4
          })
          tiff = new Tiff({
            buffer: e.target.result
          })
        } catch (_error) {
          exception = _error
          full_data = {
            title: 'Error processing TIFF file',
            body_template: Template.TiffError,
            body_data: null,
            hide_buttons: true
          }
          $('#ModalDialog').modal('hide')
          Blaze.renderWithData(Template.ModalDialog, full_data, document.body)
          throw exception
        }
        dataUrl = tiff.toDataURL()
        img = document.createElement('img')
        img.onload = function () {
          return handle_file_step_two(chosen_file, template, {
            full_image: img,
            preserve_full_image: true
          })
        }
        img.src = dataUrl
      }
    })(chosen_file)
    return tiff_reader.readAsArrayBuffer(chosen_file)
  } else {
    imageType = /^image\//
    if (imageType.test(chosen_file.type)) {
      img = document.createElement('img')
      img.onload = function () {
        return handle_file_step_two(chosen_file, template, {
          full_image: img
        })
      }
      img.file = chosen_file
      img_reader = new FileReader()
      img_reader.onload = (function (aImg) {
        return function (e) {
          aImg.src = e.target.result
        }
      })(img)
      return img_reader.readAsDataURL(chosen_file)
    } else {
      return handle_file_step_two(chosen_file, template)
    }
  }
}

Template.InsertImageDialog.destroyed = function () {
  window.image_upload_template = null
}

Template.InsertImageDialog.created = function () {
  window.image_upload_template = this
  this.selected_files = new ReactiveVar()
  this.selected_files.set([])
  this.payload_var = new ReactiveVar()
  this.upload_ready = new ReactiveVar()
  this.upload_ready.set(false)
  window.addEventListener('dragover', function (e) {
    e.preventDefault()
  }, false)
  return window.addEventListener('drop', function (e) {
    e.preventDefault()
  }, false)
}

Template.UploadProgress.helpers({
  OngoingUploadFiles: function () {
    var _id, fileObj, j, len1, ref, ref1, result, sessionVarName, store, tmp
    result = []
    ref = [['OngoingUploadFilesCache', CacheFileStore], ['OngoingUploadFilesArchive', ArchiveFileStore], ['OngoingUploadFilesZip', ZipFileStore]]
    for (j = 0, len1 = ref.length; j < len1; j++) {
      ref1 = ref[j]
      sessionVarName = ref1[0]
      store = ref1[1]
      tmp = Session.get(sessionVarName)
      for (_id in tmp) {
        fileObj = store.findOne({
          _id: _id
        })
        result.push(fileObj)
      }
    }
    return result
  }
})

Template.InsertImageDialog.helpers({
  selected_files: function () {
    var file, result, result2, template
    template = Template.instance()
    result = template.selected_files.get()
    result2 = (function () {
      var j, len1, results
      results = []
      for (j = 0, len1 = result.length; j < len1; j++) {
        file = result[j]
        results.push(file)
      }
      return results
    })()
    return result2
  }
})

Template.InsertImageDialog.events({
  'change #insert_image': function (event, template) {
    var div, file_dom_element
    template.upload_ready.set(false)
    div = template.find('#preview')
    $(div).empty()
    append_spinner(div)
    file_dom_element = template.find('#insert_image')
    if (!file_dom_element) {
      $(div).empty()
      return
    }
    template.selected_files.set(file_dom_element.files)
    return handle_files(file_dom_element.files, template)
  },
  'click #fileSelect': function (event, template) {
    var file_dom_element
    file_dom_element = template.find('#insert_image')
    if (file_dom_element) {
      file_dom_element.click()
    }
    return event.preventDefault()
  },
  'dragenter #file_form_div': function (event, template) {
    event.stopPropagation()
    return event.preventDefault()
  },
  'dragover #file_form_div': function (event, template) {
    event.stopPropagation()
    return event.preventDefault()
  },
  'drop #file_form_div': function (event, template) {
    var dt
    event.stopPropagation()
    event.preventDefault()
    dt = event.originalEvent.dataTransfer
    template.selected_files.set(dt.files)
    return handle_files(dt.files, template)
  }
})

Template.binary_data_table.onRendered(function () {
  var template
  $('.flex-images').flexImages({
    rowHeight: 200
  })
  template = Template.instance()
  update_selected(template)
})

Template.binary_data_show_brief.helpers({
  fileObjThumb: function () {
    return CacheFileStore.findOne({
      _id: this.thumbId
    })
  }
})

Template.binary_data_table_from_ids.helpers({
  idsToDocs: function () {
    return this.binary_data_ids.map(function (_id) {
      return BinaryData.findOne({
        _id: _id
      })
    })
  }
})

Template.binary_data_table.helpers({
  selectable_class: function () {
    if (Template.parentData(1).selectable_not_clickable) {
      return 'selectable'
    } else {

    }
  },
  fileObjThumb: function () {
    return CacheFileStore.findOne({
      _id: this.thumbId
    })
  },
  get_n_selected: function () {
    var N, template
    trigger_update.depend()
    template = Template.instance()
    if (template.firstNode == null) {
      return '? images'
    }
    update_selected(template)
    N = template.n_selected.get()
    if (N === 1) {
      return '1 image'
    } else {
      return N + ' images'
    }
  },
  default_thumb_width: function () {
    return DEFAULT_THUMB_WIDTH
  },
  default_thumb_height: function () {
    return DEFAULT_THUMB_HEIGHT
  }
})

update_selected = function (template) {
  var N, elements
  elements = template.findAll('.selected')
  N = elements.length
  return template.n_selected.set(N)
}

Template.binary_data_table.events({
  'click .selectable': function (event, template) {
    var $this
    $this = $(event.currentTarget)
    $this.toggleClass('selected')
    return update_selected(template)
  }
})

Template.binary_data_table.created = function () {
  this.n_selected = new ReactiveVar()
  return this.n_selected.set(0)
}

on_link_image_dialog_shown = function (data) {
  var image_id, j, len1, ref
  $('.flex-images').flexImages({
    rowHeight: 200
  })
  $('.selectable').removeClass('selected')
  ref = data.current_images
  for (j = 0, len1 = ref.length; j < len1; j++) {
    image_id = ref[j]
    $('.selectable#' + image_id).addClass('selected')
  }
  return trigger_update.changed()
}

Template.LinkExistingImageDialog.helpers({
  friendly_item_name: function () {
    var coll, my_doc
    coll = get_collection_from_name(this.collection_name)
    my_doc = coll.findOne({
      _id: this.my_id
    })
    if (my_doc != null) {
      return my_doc.name
    } else {
      return '<unknown>'
    }
  }
})
