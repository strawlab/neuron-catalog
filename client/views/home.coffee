url_converter = (url) ->
  url

Template.home.helpers
  project_name: ->
    doc = NeuronCatalogConfig.findOne({})
    if !doc?
      return
    doc.project_name
  data_authors: ->
    doc = NeuronCatalogConfig.findOne({})
    if !doc? or !doc.data_authors?
      return
    html_sanitize(doc.data_authors, url_converter )
  blurb: ->
    doc = NeuronCatalogConfig.findOne({})
    if !doc? or !doc.blurb?
      return
    return html_sanitize(doc.blurb, url_converter )
