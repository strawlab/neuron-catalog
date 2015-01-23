driver_lines_sort = {}
driver_lines_sort[window.get_sort_key("DriverLines")] = 1
neuron_types_sort = {}
neuron_types_sort[window.get_sort_key("NeuronTypes")]=1
neuropils_sort = {}
neuropils_sort[window.get_sort_key("Neuropils")] = 1

typed_name = Session.setDefault "typed_name", null

# ---- Template.driver_line_from_id_block -------------

enhance_driver_line_doc = (doc) ->
  if not doc?
    return

  if doc.is_vt_gal4_line?
    # already performed this check
    return doc

  # default values
  doc.is_vt_gal4_line = false
  doc.vdrc_url = null
  doc.brainbase_url = null

  name = doc.name.toLowerCase()
  if name.lastIndexOf("vt", 0) is 0 and endsWith(name,"gal4")
    doc.is_vt_gal4_line = true
    vt_number_str = name.substring(2, name.length-4)
    if endsWith(vt_number_str,"-")
      vt_number_str = vt_number_str.substring(0,vt_number_str.length-1)
    query =
      SEARCH_ANYPRESUF: "N"
      SEARCH_CATALOG_ID: "VDRC_Catalog"
      SEARCH_CATEGORY_ID: "VDRC_All"
      SEARCH_OPERATOR: "AND"
      SEARCH_STRING: "vt"+vt_number_str
      VIEW_SIZE: "100"
      sortAscending: "Y"
      sortOrder: "SortProductField:transformId"
    qs = $.param(query)
    doc.vdrc_url = "http://stockcenter.vdrc.at/control/keywordsearch?"+qs
    doc.brainbase_url = "http://brainbase.imp.ac.at/bbweb/#6?st=byline&q="+vt_number_str
  doc

Template.driver_line_from_id_block.helpers
  driver_line_from_id: ->
    if @_id
      # already a doc
      return enhance_driver_line_doc(this)
    my_id = this
    if @valueOf
      # If we have "valueOf" function, "this" is boxed.
      my_id = @valueOf() # unbox it
    enhance_driver_line_doc(DriverLines.findOne(my_id))

# ---- Template.AddDriverLineDialog -------------

Template.AddDriverLineDialog.helpers
  neuron_types: ->
    NeuronTypes.find()

  neuropils: ->
    Neuropils.find()

  count_cursor: (cursor) ->
    if cursor? and cursor.count? and cursor.count() > 0
        return true
    return false

  matching_driver_lines: ->
    typed_name = Session.get "typed_name"
    if !typed_name?
      return []
    if typed_name.length == 0
      return []
    cursor = DriverLines.find({name: {$regex: '^'+typed_name, $options: "i"}})

  get_linkout: ->
    {collection:"DriverLines", doc: this, my_id: @_id}

Template.AddDriverLineDialog.events
  "keyup .driver-line-lookup": (event, template) ->
    Session.set "typed_name", template.find(".name").value

# ---- Template.edit_driver_lines -------------

Template.edit_driver_lines.helpers
  driver_lines: ->
    result = []
    collection = window.get_collection_from_name(@collection_name)
    myself = collection.findOne(_id: @my_id)
    DriverLines.find().forEach (doc) ->
      doc.is_checked = false
      doc.is_checked = true  unless myself.best_driver_lines.indexOf(doc._id) is -1  if myself.hasOwnProperty("best_driver_lines")
      result.push doc
      return
    result

# ---- Template.driver_line_show -------------

Template.driver_line_show.events
  "click .edit-neuron-types": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit neuron types for driver line "+@name
      body_template_name: window.jump_table["DriverLines"].edit_neuron_types_template_name
      body_template_data:
        my_id: @_id
        collection_name: "DriverLines"
      is_save_modal: true

    window.modal_save_func = edit_neuron_types_save_func
    $("#show_dialog_id").modal "show"
    return

  "click .edit-neuropils": (e) ->
    e.preventDefault()
    Session.set "modal_info",
      title: "Edit neuropils for driver line "+@name
      body_template_name: "edit_neuropils"
      body_template_data:
        my_id: @_id
        collection_name: "DriverLines"
      is_save_modal: true

    window.modal_save_func = edit_neuropils_save_func
    $("#show_dialog_id").modal "show"
    return

# ---- Template.driver_lines -------------

Template.driver_lines.helpers
  driver_line_cursor: ->
    DriverLines.find {}, {'sort':driver_lines_sort}

Template.driver_lines.events
  "click .insert": (event, template) ->
    event.preventDefault()
    Session.set "typed_name",null
    window.dialog_template = bootbox.dialog
      message: window.renderTmp(Template.AddDriverLineDialog)
      buttons:
        save:
          label: "Save2"
          className: "btn-primary"
          callback: ->
            dialog_template = window.dialog_template
            result = save_driver_line(dialog_template)
            if result.errors
              bootbox.alert('Errors: '+result.errors.join(", "))
    return

# ------------- general functions --------

driver_line_insert_callback = (error, _id) ->
  if error?
    console.error "driver_line_insert_callback with error:", error
    bootbox.alert "Saving failed: "+error
  return

# @remove_driver_line is defined in ../neuron-catalog.coffee

save_driver_line = (template) ->
  result = {}
  doc = {}
  errors = []

  # TODO check for duplicates

  # parse
  if !template.find?
    console.error "no template.find"
    return
  doc.name = template.find(".name")[0].value
  errors.push "Name is required."  if doc.name.length < 1
  doc.neuron_types = []
  r1 = template.find(".neuron_types")
  for node in r1
    doc.neuron_types.push node.id  if node.checked

  neuropils = {}
  neuropil_fill_from_jquery(".neuropils-unspecified",template,"unspecified",neuropils)
  neuropil_fill_from_jquery(".neuropils-output",template,"output",neuropils)
  neuropil_fill_from_jquery(".neuropils-input",template,"input",neuropils)
  neuropils = neuropil_dict2arr(neuropils)

  doc.neuropils = neuropils
  doc.tags = []
  doc.images = []
  doc.comments = []
  doc.flycircuit_idids = []

  # report errors
  if errors.length > 0
    result.errors = errors
    return result

  # save result
  DriverLines.insert doc, driver_line_insert_callback
  result

@edit_driver_lines_save_func = (info, template) ->
  driver_lines = []
  my_id = Session.get("modal_info").body_template_data.my_id
  r1 = template.findAll(".driver_lines")
  for i of r1
    node = r1[i]
    driver_lines.push node.id  if node.checked
  coll_name = Session.get("modal_info").body_template_data.collection_name
  collection = window.get_collection_from_name(coll_name)
  collection.update my_id,
    $set:
      best_driver_lines: driver_lines

  {}
