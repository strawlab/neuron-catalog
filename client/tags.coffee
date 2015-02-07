editing_add_tag = new ReactiveVar(null)

Template.tags_panel.events window.okCancelEvents("#edit-tag-input",
  ok: (value) ->
    coll = window.get_collection_from_name(@collection)
    coll.update @_id,
      $addToSet:
        tags: value

    editing_add_tag.set(null)
    return

  cancel: ->
    editing_add_tag.set(null)
    return
)

Template.tags_panel.events
  "click .add-tag": (e, tmpl) ->
    editing_add_tag.set(@_id)
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
    editing_add_tag.get() == @_id

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

