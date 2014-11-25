Session.setDefault "comments_search_text", null
Session.setDefault "flycircuit_search_text", null
Session.setDefault "active_tags", {}

Template.Search.events window.okCancelEvents("#comments-search-input",
  ok: (value,evt) ->
    Session.set "comments_search_text", value
    return

  cancel: (evt) ->
    Session.set "comments_search_text", null
    return
)

Template.Search.events window.okCancelEvents("#flycircuit-search-input",
  ok: (value,evt) ->
    Session.set "flycircuit_search_text", value
    return

  cancel: (evt) ->
    Session.set "flycircuit_search_text", null
    return
)

Template.Search.events
  "click .tag-name": (event, template) ->
    event.preventDefault()
    obj = Session.get("active_tags")
    myname = this.name
    if myname of obj
      delete obj[myname]
    else
      # add item
      obj[myname] = true
    Session.set("active_tags",obj)

build_query_doc = ->
  result = {}
  doing_anything=false
  cst = Session.get("comments_search_text")
  if cst?
    if cst.length
      search_subsubdoc = {$regex: cst, $options: "i"}
      all_text_field_names = ["comments.comment","name","synonyms"]
      or_docs = []
      for tfn in all_text_field_names
        search_subdoc = {}
        search_subdoc[tfn] = search_subsubdoc
        or_docs.push search_subdoc
      result['$or'] = or_docs
      doing_anything=true


  fst = Session.get("flycircuit_search_text")
  if fst?
    fst = +fst # convert to int
    result.flycircuit_idids = fst # fst must be in array
    doing_anything=true

  atd = Session.get("active_tags")
  atl = Object.keys(atd)
  if atl.length
    result.tags = {$all: atl} # logical and
    doing_anything=true
  if !doing_anything
    result['not_exist'] = 'not_found'
  result

Template.Search.rendered = ->
  this.find("#comments-search-input").value = Session.get("comments_search_text")
  this.find("#flycircuit-search-input").value = Session.get("flycircuit_search_text")

Template.Search.helpers
  current_search: ->
    cst = Session.get("comments_search_text")
    if cst
      r = "text: '" + cst + "' "
    else
      r = ''
    fst = Session.get("flycircuit_search_text")
    if fst
      r = r + 'flycircuit_idid: ' + fst + " "
    taglist = Object.keys(Session.get("active_tags"))
    if taglist.length
      r = r + 'tags: '+ taglist
    r
  driver_line_search_cursor: ->
    query_doc = build_query_doc()
    DriverLines.find(query_doc)
  neuron_type_search_cursor: ->
    query_doc = build_query_doc()
    NeuronTypes.find(query_doc)
  neuropil_search_cursor: ->
    query_doc = build_query_doc()
    Neuropils.find(query_doc)
  binary_data_search_cursor: ->
    query_doc = build_query_doc()
    BinaryData.find(query_doc)
  get_tags: ->
    result = {}
    query_doc = {tags: {$exists: true}}
    where_doc = {tags:1,_id:0}
    DriverLines.find(query_doc,where_doc).forEach (doc) ->
      result[tag]=true for tag in doc.tags
    Object.keys(result)
    lods = [] # list of dicts
    active_tags = Session.get("active_tags")
    for tag_name in Object.keys(result)
      tmp = {name:tag_name}
      if tag_name of active_tags
        tmp.is_active_css_class='active'
      else
        tmp.is_active_css_class=''
      lods.push( tmp )
    lods
