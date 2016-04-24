import { Session } from 'meteor/session'
import { Template } from 'meteor/templating'
import { Router } from '../lib/globals-lib'

import { checkRoleClient } from './general'

Template.tags_panel.helpers({
  TagSearchQuery () {
    return {'tags': JSON.stringify([this.name])}
  }
})

Template.ReaderRequiredLayoutWithNamedURL.helpers({
  setURL () {
    // Set the URL bar of the browser to include the @name.
    let newPath = Router.current().route.path({_id: this._id, name: this.name})
    Router.go(newPath, {}, {replaceState: true})
  }
})

Template.MyLayout.helpers({
  hasNeededRoles () {
    // if user has "admin" role or @needPermissions role, authorize
    return checkRoleClient(['admin', this.needPermissions])
  },

  setTitle () {
    if (!(this.documentTitle != null)) {
      return Session.set('DocumentTitle', 'neuron catalog') // DEFAULT_TITLE
    } else {
      return Session.set('DocumentTitle', this.documentTitle)
    }
  }
})
