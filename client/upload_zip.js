import { Meteor } from 'meteor/meteor'
import { Session } from 'meteor/session'
import { ReactiveVar } from 'meteor/reactive-var'
import { Template } from 'meteor/templating'

import { ZipFileStore } from '../lib/model'

import { FS, bootbox } from './globals-client'
import { close_upload_dialog_if_no_more_uploads } from './images'
import { renderTmp } from './lib/globals'

var handle_zip_files, myclick

window.upload_template = null

Session.setDefault('OngoingUploadFilesZip', {})

export function do_upload_zip_file (chosen_file) {
  var newFile
  if (chosen_file.type !== 'application/zip') {
    console.error('chosen_file.type is not "application/zip", proceeding anyway')
  }
  newFile = new FS.File(chosen_file)
  newFile.once('uploaded', function () {
    var tmp
    tmp = Session.get('OngoingUploadFilesZip')
    delete tmp[newFile._id]
    Session.set('OngoingUploadFilesZip', tmp)
    close_upload_dialog_if_no_more_uploads()
    return Meteor.call('process_zip', function (error, result) {
      var elem, hasError, i, len
      if (error) {
        console.error('server callback with error', error)
        hasError = true
      } else {
        console.log('server callback with result', result)
        hasError = false
        for (i = 0, len = result.length; i < len; i++) {
          elem = result[i]
          if (elem.jsonResults.errors.length) {
            hasError = true
          }
        }
      }
      if (hasError) {
        return bootbox.alert('Error processing the uploaded file. Some entries may be corrupt or incomplete.')
      } else {
        return bootbox.alert('Upload processed OK.')
      }
    })
  })
  bootbox.dialog({
    message: renderTmp(Template.UploadProgress),
    title: 'Upload Progress'
  })
  return ZipFileStore.insert(newFile, function (error, fileObj) {
    var tmp
    if (error != null) {
      console.error(error)
      bootbox.alert('There was an error uploading the file')
    }
    tmp = Session.get('OngoingUploadFilesZip')
    tmp[fileObj._id] = true
    return Session.set('OngoingUploadFilesZip', tmp)
  })
}

Template.UploadDataDialog.destroyed = function () {
  window.upload_template = null
}

Template.UploadDataDialog.created = function () {
  window.upload_template = this
  this.selected_zip_files_var = new ReactiveVar()
  this.selected_zip_files_var.set([])
  this.zip_upload_ready = new ReactiveVar()
  return this.zip_upload_ready.set(false)
}

Template.UploadDataDialog.helpers({
  selected_zip_files: function () {
    var f, i, len, ref, results
    ref = Template.instance().selected_zip_files_var.get()
    results = []
    for (i = 0, len = ref.length; i < len; i++) {
      f = ref[i]
      results.push(f)
    }
    return results
  }
})

myclick = function (template, event, selector) {
  var file_dom_element
  file_dom_element = template.find(selector)
  if (file_dom_element) {
    file_dom_element.click()
  }
  return event.preventDefault()
}

Template.UploadDataDialog.events({
  'click #zipSelect': function (event, template) {
    return myclick(template, event, '#upload-zip-data')
  },
  'change #upload-zip-data': function (event, template) {
    var file_dom_element
    template.zip_upload_ready.set(false)
    file_dom_element = template.find('#upload-zip-data')
    if (!file_dom_element) {
      return
    }
    template.selected_zip_files_var.set(file_dom_element.files)
    return handle_zip_files(file_dom_element.files, template)
  },
  'dragenter .mydrag': function (event, template) {
    event.stopPropagation()
    return event.preventDefault()
  },
  'dragover .mydrag': function (event, template) {
    event.stopPropagation()
    return event.preventDefault()
  },
  'drop #upload-zip-data-div': function (event, template) {
    var dt
    event.stopPropagation()
    event.preventDefault()
    dt = event.originalEvent.dataTransfer
    template.selected_zip_files_var.set(dt.files)
    return handle_zip_files(dt.files, template)
  }
})

handle_zip_files = function (fileList, template) {
  if (fileList.length === 0) {
    return
  }
  if (fileList.length > 1) {
    console.error('More than one file selected')
    return
  }
  return template.zip_upload_ready.set(true)
}