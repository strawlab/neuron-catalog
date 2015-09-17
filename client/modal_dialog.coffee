Template.ModalDialog.onRendered ->
  body_div = this.$("#modal-dialog-body")[0]
  Blaze.renderWithData( @data.body_template, @data.body_data, body_div )

  options = {}
  $(@firstNode).modal(options)

  if @data.render_complete?
    @data.render_complete( this )

Template.ModalDialog.events
  "hidden.bs.modal": (event, template) ->
     Blaze.remove(template.view)

Template.ModalDialog.helpers
  show_buttons: ->
    template = Template.instance()
    if template.data.hide_buttons?
      if template.data.hide_buttons
        return false
    return true
