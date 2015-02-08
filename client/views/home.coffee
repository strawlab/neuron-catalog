url_converter = (url) ->
  url

Template.home.helpers
  project_name: ->
    NeuronCatalogConfig.findOne({}).project_name
  data_authors: ->
    html_sanitize(NeuronCatalogConfig.findOne({}).data_authors, url_converter )
  blurb: ->
    html_sanitize(NeuronCatalogConfig.findOne({}).blurb, url_converter )
