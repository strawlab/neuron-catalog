Template.FlyLightQueryLauncher.events
  "click .flylight-post": (event, template) ->

    name = @driver_line_name.toLowerCase()
    if name.lastIndexOf("gmr", 0) is 0 # e.g. GMR42F06-Gal4
      name = name.substr(2) # R42F06-Gal4

    short_name = name.substr(0,6) # R42F06-Gal4
    short_name = short_name.toUpperCase()

    formData = []
    formData.push(["_search_toggle", "general"])
    formData.push(["line", short_name])
    blank = ["lines","genes","mlines","dlines"]
    for blank_key in blank
      formData.push([blank_key, ""])
    formData.push(["_gsearch", "Search"])
    formData.push(["_search_logic", "AND"])
    formData.push(["_disc_search_logic", "AND"])
    formData.push(["_embryo_search_logic", "AND"])
    formData.push([".cgifields", "_search_toggle"])
    formData.push([".cgifields", "dline"])
    formData.push([".cgifields", "mline"])
    formData.push([".cgifields", "term"])
    formData.push([".cgifields", "lline"])
    formData.push([".cgifields", "gfp_pattern"])
    formData.push([".cgifields", "line"])
    formData.push([".cgifields", "lterm"])

    form = document.createElement('form')
    form.setAttribute 'method', 'POST'
    form.setAttribute 'action', 'http://flweb.janelia.org/cgi-bin/flew.cgi'

    for el in formData
      key = el[0]
      value = el[1]
      hiddenField = document.createElement('input')
      hiddenField.setAttribute 'type', 'hidden'
      hiddenField.setAttribute 'name', key
      hiddenField.setAttribute 'value', value
      form.appendChild hiddenField

    document.body.appendChild(form)
    form.submit()
