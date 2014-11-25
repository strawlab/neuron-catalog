Template.tags_panel.events window.okCancelEvents("#edit-tag-input",
  ok: (value) ->
    coll = window.get_collection_from_name(@collection)
    coll.update @_id,
      $addToSet:
        tags: value

    Session.set "editing_add_tag", null
    return

  cancel: ->
    Session.set "editing_add_tag", null
    return
)

Template.tags_panel.events
  "click .add-tag": (e, tmpl) ->
    Session.set "editing_add_tag", @_id
    Deps.flush() # update DOM before focus
    window.activateInput tmpl.find("#edit-tag-input")
    return

  "click .remove": (evt) ->
    tag = @name
    parent_id = @parent_id
    evt.target.parentNode.style.opacity = 0
    coll = window.get_collection_from_name(@collection)

    # wait for CSS animation to finish
    Meteor.setTimeout (->
      coll.update
        _id: parent_id
      ,
        $pull:
          tags: tag

      return
    ), 300
    return

Template.tags_panel.helpers
  adding_tag: ->
    Session.equals "editing_add_tag", @_id

  tag_dicts: ->
    result = []

    if !@tags?
      return result

    for name in @tags
      tmp =
        name: name
        parent_id: @_id
        collection: @collection

      result.push tmp
    result

