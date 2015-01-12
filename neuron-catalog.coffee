Router.configure
  layoutTemplate: "MyLayout"
  notFoundTemplate: "PageNotFound"

Router.setTemplateNameConverter (str) ->
  str

always_include_name_in_path_action = (controller, coll, template_name) ->
  using_canonical_name=false
  doc = coll.findOne _id: controller.params._id
  if controller.params.name?
    if doc? and controller.params.name == doc.name
      using_canonical_name = true

  if doc?
    if using_canonical_name
      controller.render template_name
    else
      route_name = controller.route.getName()
      controller.redirect( route_name, {_id:controller.params._id,name:doc.name} )
  else
    # The _id is not in the database. Should maybe do a 404. For
    # now, render with blank data.
    # FIXME in the future (See
    # https://github.com/EventedMind/iron-router/issues/237 )
    controller.render "PageNotFound"

Router.route "/",
  name: "home"
  action: ->
    @render "Home"

Router.route "/driver_lines"

Router.route "/driver_lines/:_id/:name?",
  name: "driver_line_show"
  action: ->
    always_include_name_in_path_action(this, DriverLines, "driver_line_show")
  data: ->
    DriverLines.findOne _id: @params._id

Router.route "/neuron_types"

Router.route "/neuron_types/:_id/:name?",
  name: "neuron_type_show"
  action: ->
    always_include_name_in_path_action(this, NeuronTypes, "neuron_type_show")
  data: ->
    NeuronTypes.findOne _id: @params._id

Router.route "/neuropils"

Router.route "/neuropils/:_id/:name?",
  name: "neuropil_show"
  action: ->
    always_include_name_in_path_action(this, Neuropils, "neuropil_show")
  data: ->
    Neuropils.findOne _id: @params._id

Router.route "/binary_data"

Router.route "/binary_data/:_id/:name?",
  name: "binary_data_show"
  action: ->
    always_include_name_in_path_action(this, BinaryData, "binary_data_show")
  data: ->
    BinaryData.findOne _id: @params._id

Router.route "/RecentChanges"

Router.route "/Search", ->
  @render "Search",
    data: ->
      @params
  return

@remove_driver_line = (my_id) ->
  rdl = (doc) ->
    setter = {}
    for i of @fields
      field = @fields[i]
      index = doc[field].indexOf(@my_id)
      unless index is -1
        doc[field].splice index, 1
        setter[field] = doc[field]
    @coll.update doc._id,
      $set: setter

    return
  NeuronTypes.find(driver_lines: my_id).forEach rdl,
    my_id: my_id
    coll: NeuronTypes
    fields: ["best_driver_lines"]

  DriverLines.remove my_id
  return

@remove_binary_data = (my_id) ->
  rnt = (doc) ->
    index = doc[@field_name].indexOf(@my_id)

    # No need to check for index==-1 because we know it does not (except race condition).
    doc[@field_name].splice index, 1
    t2 = {}
    t2[@field_name] = doc[@field_name]
    @coll.update doc._id,
      $set: t2

    return
  field_name = "images"
  query = {}
  query[field_name] = my_id
  DriverLines.find(query).forEach rnt,
    my_id: my_id
    coll: DriverLines
    field_name: field_name

  doc = BinaryData.findOne(my_id)

  console.log "warning: should delete file on server.",doc.secure_url
  BinaryData.remove my_id
  return

@remove_neuron_type = (my_id) ->
  rnt = (doc) ->
    index = doc.neuron_types.indexOf(@my_id)

    # No need to check for index==-1 because we know it does not (except race condition).
    doc.neuron_types.splice index, 1
    @coll.update doc._id,
      $set:
        neuron_types: doc.neuron_types

    return
  DriverLines.find(neuron_types: my_id).forEach rnt,
    my_id: my_id
    coll: DriverLines

  NeuronTypes.remove my_id
  return

@remove_neuropil = (my_id) ->
  rn = (doc) ->
    index = doc.neuropils.indexOf(@my_id)

    # No need to check for index==-1 because we know it does not (except race condition).
    doc.neuropils.splice index, 1
    @coll.update doc._id,
      $set:
        neuropils: doc.neuropils

    return
  DriverLines.find(neuron_types: my_id).forEach rn,
    my_id: my_id
    coll: DriverLines

  NeuronTypes.find(neuron_types: my_id).forEach rn,
    my_id: my_id
    coll: NeuronTypes

  Neuropils.remove my_id
  return
