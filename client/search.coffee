Session.setDefault "comments_search_text", null
Session.setDefault "flycircuit_search_text", null
Session.setDefault "active_tags", {}

update_url_bar = ->
  q = {}

  cst = Session.get("comments_search_text")
  if cst?
    q['text'] = cst

  fst = Session.get("flycircuit_search_text")
  if fst?
    q['idid'] = fst

  taglist = Object.keys(Session.get("active_tags"))
  if taglist.length
    q['tags'] = JSON.stringify(taglist)

  Router.go("Search", {}, {query:q})

Template.Search.events window.okCancelEvents("#comments-search-input",
  ok: (value,evt) ->
    Session.set "comments_search_text", value
    update_url_bar()
    return

  cancel: (evt) ->
    Session.set "comments_search_text", null
    update_url_bar()
    return
)

Template.Search.events window.okCancelEvents("#flycircuit-search-input",
  ok: (value,evt) ->
    Session.set "flycircuit_search_text", value
    update_url_bar()
    return

  cancel: (evt) ->
    Session.set "flycircuit_search_text", null
    update_url_bar()
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
    update_url_bar()

del = (obj, key) ->
  val =  obj[key]
  delete obj[key]
  val

build_query_doc = (orig) ->
  orig_data = orig.query
  data = {}
  for key of orig_data
    data[key] = orig_data[key]

  result = {}
  doing_anything=false
  delete data['hash'] # iron:router puts this in. we ignore it.

  cst = del(data,'text')
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

  fst = del(data,'idid')
  if fst?
    if fst=="*"
      result.flycircuit_idids = {$exists:1}
    else
      fst = +fst # convert to int
      result.flycircuit_idids = fst # fst must be in array
    doing_anything=true

  atl_json = del(data,'tags')
  if atl_json? and atl_json.length
    atl = JSON.parse(atl_json)
    result.tags = {$all: atl} # logical and
    doing_anything=true
  if !doing_anything
    return

  if Object.keys(data).length
    console.log("ERROR: unknown search parameters:",data)
  result

Template.Search.rendered = ->
  if @data.text?
    Session.set("comments_search_text",@data.text)
  if @data.idid?
    Session.set("flycircuit_search_text",@data.idid)
  if @data.tags?
    atl = JSON.parse(@data.tags)
    taglist = {}
    for tag in atl
      taglist[tag] = true
    Session.set("active_tags",taglist)
  this.find("#comments-search-input").value = Session.get("comments_search_text")
  this.find("#flycircuit-search-input").value = Session.get("flycircuit_search_text")

Template.Search.helpers
  current_search: ->
    query_doc = build_query_doc(this)
    if query_doc?
      JSON.stringify(query_doc)
  driver_line_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
      DriverLines.find(query_doc)
  neuron_type_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
      NeuronTypes.find(query_doc)
  neuropil_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
      Neuropils.find(query_doc)
  binary_data_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
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
