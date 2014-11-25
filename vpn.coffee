Router.configure layoutTemplate: "MyLayout"
Router.map ->
  @route "home",
    path: "/"

  @route "driver_lines"
  @route "driver_line_show",
    path: "/driver_lines/:_id"
    data: ->
      DriverLines.findOne @params._id

  @route "neuron_types"
  @route "neuron_type_show",
    path: "/neuron_types/:_id"
    data: ->
      NeuronTypes.findOne @params._id

  @route "neuropils"
  @route "neuropil_show",
    path: "/neuropils/:_id"
    data: ->
      Neuropils.findOne @params._id

  @route "binary_data"
  @route "binary_data_show",
    path: "/binary_data/:_id"
    data: ->
      BinaryData.findOne @params._id

  @route "RecentChanges"

  @route "Search",
    data: ->
      @params

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
  
  S3.delete doc.relative_url
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
