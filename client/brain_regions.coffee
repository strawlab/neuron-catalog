driver_lines_sort = {}
driver_lines_sort[window.get_sort_key("DriverLines")] = 1
neuron_types_sort = {}
neuron_types_sort[window.get_sort_key("NeuronTypes")]=1
brain_regions_sort = {}
brain_regions_sort[window.get_sort_key("BrainRegions")] = 1

#----------
Template.brain_region_from_id_block.helpers
  brain_region_from_id: ->
    if !this? or Object.keys(this).length ==0
      return # Cannot deal with this situation...

  # We can get called 3 ways:
  # 1) From something that keeps track of what expression type is in the brain_region.
  # 2) Already as a full document from the database.
  # 3) As just an id to the brain_region.
    if @type?
      # This is case #1 described above.
      # object with keys ["_id", "type"]:
      my_id = @_id
      my_types = @type
      insert_types = true
    else
      insert_types = false
      if @_id?
        # This is case #2 described above.
        # already a doc
        return this

      # This is case #3 described above.
      my_id = this

      if @valueOf
        # If we have "valueOf" function, "this" is boxed.
        my_id = @valueOf() # unbox it

    result = BrainRegions.findOne my_id
    if !result?
      return
    result.my_types = []
    if insert_types
      result.my_types = my_types
    result

brain_region_insert_callback = (error, _id) ->
  if error?
    console.error "brain_region_insert_callback with error:", error
    bootbox.alert "Saving failed: "+error
    return

# @remove_brain_region is defined in ../neuron-catalog.coffee

@save_brain_region = (template) ->
  result = {}

  # parse
  name = template.find(".name")[0].value

  # find errors
  errors = []
  errors.push "Name is required."  if name.length < 1

  # report errors
  if errors.length > 0
    result.errors = errors
    return result

  # save result
  BrainRegions.insert
    name: name
    tags: []
    comments: []
    images: []
  , brain_region_insert_callback
  result

Template.EditBrainRegionsDialog.helpers
  brain_regions: ->
    result = []
    collection = window.get_collection_from_name(@collection_name)
    myself = collection.findOne(_id: @my_id)
    BrainRegions.find({},{sort:brain_regions_sort}).forEach (doc) ->
      doc.unspecific_is_checked = false
      doc.output_is_checked = false
      doc.input_is_checked = false

      for tmp in myself.brain_regions
        if tmp._id == doc._id
          if "unspecified" in tmp.type
            doc.unspecific_is_checked = true
          if "output" in tmp.type
            doc.output_is_checked = true
          if "input" in tmp.type
            doc.input_is_checked = true

      result.push doc
      return

    result

@brain_region_fill_from_jquery = (selector, template, brain_region_type, result) ->
  for node in template.find(selector)
    if node.checked
      if !result.hasOwnProperty(node.id)
        result[node.id] = []
      result[node.id].push brain_region_type
  return

@brain_region_dict2arr = (brain_regions) ->
  result = []
  for _id, tarr of brain_regions
    result.push( {"_id":_id, "type":tarr} )
  result

@edit_brain_regions_save_func = (template, coll_name, my_id) ->
  brain_regions = {}
  brain_region_fill_from_jquery(".brain_regions-unspecified",template,"unspecified",brain_regions)
  brain_region_fill_from_jquery(".brain_regions-output",template,"output",brain_regions)
  brain_region_fill_from_jquery(".brain_regions-input",template,"input",brain_regions)
  brain_regions = brain_region_dict2arr(brain_regions)

  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      brain_regions: brain_regions

Template.brain_region_show.helpers
  driver_lines_referencing_me: ->
    DriverLines = window.get_collection_from_name("DriverLines") # FIXME: why do I need this?
    DriverLines.find brain_regions:
      $elemMatch:
        _id: @_id

  neuron_types_referencing_me: ->
    NeuronTypes.find brain_regions:
      $elemMatch:
        _id: @_id

Template.brain_region_table.helpers
  showExpressionType: (kw) ->
    data = Template.parentData(kw.hash.parent)
    if data.show_expression_type?
      return data.show_expression_type
    else
      return true

  driver_lines_referencing_me: ->
    DriverLines = window.get_collection_from_name("DriverLines") # FIXME: why do I need this?
    DriverLines.find brain_regions:
      $elemMatch:
        _id: @_id

  neuron_types_referencing_me: ->
    NeuronTypes.find brain_regions:
      $elemMatch:
        _id: @_id

Template.brain_regions.events
  "click .insert": (event, template) ->
    coll = "BrainRegions"
    event.preventDefault()
    window.dialog_template = bootbox.dialog
      title: "Add a new brain region"
      message: window.renderTmp(Template.AddBrainRegionDialog)
      buttons:
        close:
          label: "Close"
        save:
          label: "Save"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            result = save_brain_region(dialog_template)
            if result.errors
              bootbox.alert('Errors: '+result.errors.join(", "))
    window.dialog_template.on("shown.bs.modal", ->
      $(".name").focus()
    )
    window.dialog_template.on("submit", ->
      window.dialog_template.find(".btn-primary").click()
      false
    )

Template.brain_regions.helpers
  brain_region_cursor: ->
    BrainRegions.find {},{sort:brain_regions_sort}
