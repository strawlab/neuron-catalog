import { Template } from 'meteor/templating'

Template.FlyLightQueryLauncher.events({
  ['click .flylight-post'] (event, template) {
    let name = this.driver_line_name.toLowerCase()
    if (name.lastIndexOf('gmr', 0) === 0) { // e.g. GMR42F06-Gal4
      name = name.substr(2) // R42F06-Gal4
    }

    let short_name = name.substr(0, 6) // R42F06-Gal4
    short_name = short_name.toUpperCase()

    let formData = []
    formData.push(['_search_toggle', 'general'])
    formData.push(['line', short_name])
    let blank = ['lines', 'genes', 'mlines', 'dlines']
    for (let i = 0; i < blank.length; i++) {
      let blank_key = blank[i]
      formData.push([blank_key, ''])
    }
    formData.push(['_gsearch', 'Search'])
    formData.push(['_search_logic', 'AND'])
    formData.push(['_disc_search_logic', 'AND'])
    formData.push(['_embryo_search_logic', 'AND'])
    formData.push(['.cgifields', '_search_toggle'])
    formData.push(['.cgifields', 'dline'])
    formData.push(['.cgifields', 'mline'])
    formData.push(['.cgifields', 'term'])
    formData.push(['.cgifields', 'lline'])
    formData.push(['.cgifields', 'gfp_pattern'])
    formData.push(['.cgifields', 'line'])
    formData.push(['.cgifields', 'lterm'])

    let form = document.createElement('form')
    form.setAttribute('method', 'POST')
    form.setAttribute('action', 'http://flweb.janelia.org/cgi-bin/flew.cgi')

    for (let j = 0; j < formData.length; j++) {
      let el = formData[j]
      let key = el[0]
      let value = el[1]
      let hiddenField = document.createElement('input')
      hiddenField.setAttribute('type', 'hidden')
      hiddenField.setAttribute('name', key)
      hiddenField.setAttribute('value', value)
      form.appendChild(hiddenField)
    }

    form.setAttribute('target', '_blank') // new window http://stackoverflow.com/a/179015
    document.body.appendChild(form)
    return form.submit()
  }
})
