comments_search_text = new ReactiveVar(null)
flycircuit_search_text = new ReactiveVar(null)
active_tags = new ReactiveVar({})

update_url_bar = ->
  q = {}

  cst = comments_search_text.get()
  if cst?
    q['text'] = cst

  fst = flycircuit_search_text.get()
  if fst?
    q['idid'] = fst

  taglist = Object.keys(active_tags.get())
  if taglist.length
    q['tags'] = JSON.stringify(taglist)

  Router.go("Search", {}, {query:q})

Template.Search.events window.okCancelEvents("#comments-search-input",
  ok: (value,evt) ->
    comments_search_text.set(value)
    update_url_bar()
    return

  cancel: (evt) ->
    comments_search_text.set(null)
    update_url_bar()
    return
)

Template.Search.events window.okCancelEvents("#flycircuit-search-input",
  ok: (value,evt) ->
    flycircuit_search_text.set(value)
    update_url_bar()
    return

  cancel: (evt) ->
    flycircuit_search_text.set(null)
    update_url_bar()
    return
)

Template.Search.events
  "click .tag-name": (event, template) ->
    event.preventDefault()
    obj = active_tags.get()
    myname = this.name
    if myname of obj
      delete obj[myname]
    else
      # add item
      obj[myname] = true
    active_tags.set(obj)
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
      result['$where'] = 'this.flycircuit_idids.length>=1'
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
    console.error("ERROR: unknown search parameters:",data)
  result

Template.Search.rendered = ->
  if !@find("#comments-search-input")?
    return
  if @data.text?
    comments_search_text.set(@data.text)
  if @data.idid?
    flycircuit_search_text.set(@data.idid)
  if @data.tags?
    atl = JSON.parse(@data.tags)
    taglist = {}
    for tag in atl
      taglist[tag] = true
    active_tags.set(taglist)
  this.find("#comments-search-input").value = comments_search_text.get()
  this.find("#flycircuit-search-input").value = flycircuit_search_text.get()

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
  brain_region_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
      BrainRegions.find(query_doc)
  binary_data_search_cursor: ->
    query_doc = build_query_doc(this)
    if query_doc?
      BinaryData.find(query_doc)
  get_tags: ->
    coll_names_with_tags = []
    for coll_name of Schemas
      if "tags" in Schemas[coll_name].objectKeys()
        coll_names_with_tags.push coll_name
    result = {}
    query_doc = {tags: {$exists: true}}
    where_doc = {tags:1,_id:0}
    for coll_name in coll_names_with_tags
      collection = window.get_collection_from_name(coll_name)
      collection.find(query_doc,where_doc).forEach (doc) ->
        result[tag]=true for tag in doc.tags
    lods = [] # list of dicts
    my_active_tags = active_tags.get()
    for tag_name of result
      tmp = {name:tag_name}
      if tag_name of my_active_tags
        tmp.is_active_css_class='active'
      else
        tmp.is_active_css_class=''
      lods.push( tmp )
    lods
