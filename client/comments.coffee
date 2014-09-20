converter = new Showdown.converter();

Template.comments_panel.comment_preview = ->
  Session.get "comment_preview_html"

Template.comments_panel.is_previewing_comment = ->
  Session.equals "comment_preview_mode", true

Template.comments_panel.is_writing_attrs = ->
  "vis-hidden"  if Session.equals("comment_preview_mode", true)

Template.comments_panel.is_previewing_attrs = ->
  "vis-hidden"  if Session.equals("comment_preview_mode", false)

Template.comments_panel.events
  "click .write-comment": (event, template) ->
    event.preventDefault()
    Session.set "comment_preview_mode", false
    Session.set "comment_preview_html", null
    return

  "click .preview-comment": (event, template) ->
    event.preventDefault()
    ta = template.find("textarea.comments")
    comments_raw = ta.value
    result = converter.makeHtml(comments_raw)
    Session.set "comment_preview_mode", true
    Session.set "comment_preview_html", result
    return

  "click .save": (event, template) ->
    event.preventDefault()
    ta = template.find("textarea.comments")
    comments_raw = ta.value
    ta.value = ""
    Session.set "comment_preview_html", null
    collection = get_collection_from_name(@show_name)
    cdict = comment: comments_raw # FIXME: add auth stuff and timestamp on server.
    collection.update @_id,
      $push:
        comments: cdict

    return

Template.show_comments.show_markdown = (comment) ->
  result = converter.makeHtml(comment.comment)
  result

Template.show_comments.wrapped_comments = ->
  result = []
  for i of @comments
    doc = {}
    doc.comment = @comments[i]
    doc.parent_show_name = @show_name
    doc.parent_id = @_id
    result.push doc
  result

Template.show_comments.events "click .delete": (evt, tmpl) ->
  collection = get_collection_from_name(@parent_show_name)
  collection.update
    _id: @parent_id
  ,
    $pull:
      comments: @comment

  return
