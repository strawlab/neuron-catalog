import { Template } from 'meteor/templating'
import { Tracker } from 'meteor/tracker'
import { Blaze } from 'meteor/blaze'
import $ from 'jquery'

import { do_upload_data_file } from './upload_data'

let get_fname_base = function () {
  let now = new Date()
  let nowstr = now.toISOString()
  const fname_base = nowstr.replace('T', '_').replace(/\:/g, '-').replace(/\..+/, '')
  return fname_base
}

Template.DataImportExportLauncher.events({
  ['click .launch-data-import-dialog'] (event, template) {
    event.preventDefault()
    let full_data = {
      title: 'Upload data',
      body_template: Template.UploadDataDialog,
      body_data: null,
      save_label: 'Upload',
      render_complete (parent_template) {
        let body_template = window.upload_template

        Tracker.autorun(function () {
          let upload_ready = body_template.zip_upload_ready.get()
          let do_upload_button = parent_template.$('#modal-dialog-save')
          if (upload_ready) {
            return do_upload_button.removeClass('disabled')
          } else {
            return do_upload_button.addClass('disabled')
          }
        })

        return parent_template.$('#modal-dialog-save').on('click', function (event) {
          template = window.upload_template
          if (template.zip_upload_ready.get()) {
            let fileList = template.selected_zip_files_var.get()
            let chosen_file = fileList[0]
            return do_upload_data_file(chosen_file)
          }
        }
        )
      }
    }

    return Blaze.renderWithData(Template.ModalDialog, full_data, document.body)
  },

  ['click #download-zip'] (event, template) {
    // We want to let the default event fire (to initiate the
    // download). Here, we just close the download window.
    return $('#ModalDialog').modal('hide')
  }
})

let get_zip_fname = function () {
  let fname_base = get_fname_base()
  return `neuron-catalog-data_${fname_base}.zip`
}

Template.DataImportExportLauncher.helpers({
  zip_filename () {
    return get_zip_fname()
  },
  zip_filename_str () {
    let fname = get_zip_fname()
    return `filename=${fname}`
  }
})
