import { Template } from 'meteor/templating'
import { NeuronCatalogConfig } from '../lib/model'

import { html_sanitize } from './globals-client'

let url_converter = url => url

Template.home.helpers({
  project_name () {
    let doc = NeuronCatalogConfig.findOne({})
    if (!(doc != null)) {
      return
    }
    return doc.project_name
  },
  data_authors () {
    let doc = NeuronCatalogConfig.findOne({})
    if (!(doc != null) || !(doc.data_authors != null)) {
      return
    }
    return html_sanitize(doc.data_authors, url_converter)
  },
  blurb () {
    let doc = NeuronCatalogConfig.findOne({})
    if (!(doc != null) || !(doc.blurb != null)) {
      return
    }
    return html_sanitize(doc.blurb, url_converter)
  }
})
