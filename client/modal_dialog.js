import { Template } from 'meteor/templating'
import { Blaze } from 'meteor/blaze'
import $ from 'jquery'

Template.ModalDialog.onRendered(function () {
  let body_div = this.$('#modal-dialog-body')[0]
  Blaze.renderWithData(this.data.body_template, this.data.body_data, body_div)

  let options = {}
  $(this.firstNode).modal(options)

  if (this.data.render_complete != null) {
    return this.data.render_complete(this)
  }
})

Template.ModalDialog.events({
  ['hidden.bs.modal'] (event, template) {
    return Blaze.remove(template.view)
  }
})

Template.ModalDialog.helpers({
  show_buttons () {
    let template = Template.instance()
    if (template.data.hide_buttons != null) {
      if (template.data.hide_buttons) {
        return false
      }
    }
    return true
  }
})
