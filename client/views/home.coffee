Template.registerHelper "config", ->
  NeuronCatalogConfig.findOne({})
