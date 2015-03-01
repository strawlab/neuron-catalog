# check for a new release of neuron catalog

on_version_received = (data,status,xhr) ->
  if status != "success"
    return
  is_up_to_date = compareVersions(neuron_catalog_version, data.version)
  if !is_up_to_date
    Notifications.info('A new version of neuron-catalog is available',
      data.description_html)

check_version = ->
  $.ajax(
    url: "http://strawlab.org/neuron-catalog/latest-release.json"
    dataType: 'json'
    success: on_version_received
  )

initial_check_version = ->
  check_version()
  Meteor.setInterval( check_version, 12*1000*60*60 ) # every 12 hours check version

Meteor.startup ->
  Meteor.setTimeout( initial_check_version, 30*1000 ) # in 30 seconds check version

# From http://stackoverflow.com/a/6832670/1633026
# return true if 'installed' (considered as a JRE version string) is
# greater than or equal to 'required' (again, a JRE version string).
compareVersions = (installed, required) ->
  a = installed.split('.')
  b = required.split('.')
  i = 0
  while i < a.length
    a[i] = Number(a[i])
    ++i
  i = 0
  while i < b.length
    b[i] = Number(b[i])
    ++i
  if a.length == 2
    a[2] = 0
  if a[0] > b[0]
    return true
  if a[0] < b[0]
    return false
  if a[1] > b[1]
    return true
  if a[1] < b[1]
    return false
  if a[2] > b[2]
    return true
  if a[2] < b[2]
    return false
  true
