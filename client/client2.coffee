UI.body.getData = ->
  "data"

# -------
Template.registerHelper "zxkp", ->
  #  return {'class':'label label-default'};
  class: "zxkp"

Template.registerHelper "currentUser", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  Meteor.user()

Template.registerHelper "login_message", ->
  # Mimic the normal meteor accounts system from IronRouter template.
  "You must be logged in to see or add data."
