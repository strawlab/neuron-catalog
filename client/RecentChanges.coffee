recent_changes_n_days = new ReactiveVar(2)

Template.RecentChanges.helpers
  last_n_days: ->
    recent_changes_n_days.get()

Template.RecentChanges.events
  "input, change": (e) ->
    e.preventDefault()
    n_days = $('#last_n_days_widget').val()
    recent_changes_n_days.set(n_days)

Template.ChangeList.helpers
  wrapped_changes: ->
    result = []
    collection=@collname # create local variable
    coll = window.get_collection_from_name(@collname)
    options = {'sort':{'last_edit_time':-1}}#,'limit':10}

    last_n_days = @last_n_days

    cur = new Date()
    msec = last_n_days*24*60*60*1000
    past = cur - msec

    query = {'last_edit_time':{'$gt':past}}
    coll.find(query, options).forEach (row) ->
      result.push {collection:collection, my_id:row._id, doc:row}
    result
