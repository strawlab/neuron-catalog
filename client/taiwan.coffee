Session.setDefault "editing_flycircuit_idid", null

Template.FlyCircuitPanel.events window.okCancelEvents("#edit-flycircuit-input",
  ok: (value) ->
    coll = window.get_collection_from_name(@collection)
    coll.update @_id,
      $addToSet:
        flycircuit_idids: +value # plus sign converts to integer

    Session.set "editing_flycircuit_idid", null
    return

  cancel: ->
    Session.set "editing_flycircuit_idid", null
    return
)

Template.FlyCircuitPanel.events
  "click .add-flycircuit-idid": (e, tmpl) ->
    Session.set "editing_flycircuit_idid", @_id
    Deps.flush() # update DOM before focus
    window.activateInput tmpl.find("#edit-flycircuit-input")
    return

  "click .remove": (evt) ->
    flycircuit_idid = @name
    parent_id = @parent_id
    coll = window.get_collection_from_name(@collection)

    # wait for CSS animation to finish
    Meteor.setTimeout (->
      coll.update
        _id: parent_id
      ,
        $pull:
          flycircuit_idids: flycircuit_idid

      return
    ), 300
    return

Template.FlyCircuitPanel.helpers
  adding_flycircuit_idid: ->
    Session.equals "editing_flycircuit_idid", @_id

  idid_dicts: ->
    result = []

    if !@flycircuit_idids?
      return result

    for idid in @flycircuit_idids
      tmp =
        name: idid
        parent_id: @_id
        collection: @collection

      result.push tmp
    result
