_ = require 'lodash'
React = require 'react'
Bootstrap = require 'react-bootstrap'

Popover = React.createFactory Bootstrap.Popover
OverlayTrigger = React.createFactory Bootstrap.OverlayTrigger

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    tags = _ (@props.item.fullAttributes?.characteristic ? [])
      .filter (characteristic) ->
        characteristic.text.substring(0, 4) == 'tag:'
      .map (characteristic, index) =>
        characteristic.text.substring 4
      .value()
    tags: tags

  getTagElements: ->
    _.map @state.tags, (tag, index) =>
      DOM.p
        key: "item-#{@props.item._id}-tag-#{tag}"
      ,
        DOM.em
          className: 'glyphicon glyphicon-tag'
          style:
            opacity: 0.5
        DOM.span null, " #{tag} "
        DOM.a
          href: '#'
          onClick: @removeTag tag
        , '[x]'

  addTag: (e) ->
    e.preventDefault()
    el = React.findDOMNode @refs.newTag
    newTag = el.value
    url = "/admin/item/#{@props.item._id}/tags/add/#{newTag}.json"
    @props.request.post url, {}, (err, data) ->
      console.log 'addTag result', url, err, data
    tags = _.uniq @state.tags.concat newTag
    el.value = ''
    @setState
      tags: tags

  removeTag: (tag) ->
    (e) =>
      e.preventDefault()
      tags = _.filter @state.tags, (t) ->
        t != tag
      url = "/admin/item/#{@props.item._id}/tags/remove/#{tag}.json"
      @props.request.post url, {}, (err, data) ->
        console.log 'removeTag result', url, err, data
      @setState
        tags: tags

  render: ->
    tagElements = @getTagElements()
    if tagElements.length == 0
      tagElements = DOM.div null, 'no tags..'

    pop = Popover
      title: 'Tags'
    ,
      DOM.div
        style:
          minWidth: '100px'
      ,
        tagElements
        DOM.div null,
          DOM.form
            onSubmit: @addTag
          ,
            DOM.input
              ref: 'newTag'
              placeholder: ' add tag'
            DOM.a
              href: '#'
              className: 'btn btn-default btn-sm'
              onClick: @addTag
            , 'add'

    OverlayTrigger
      trigger: 'click'
      placement: 'bottom'
      overlay: pop
      rootClose: true
    ,
      DOM.a
        className: 'stream-item-control'
        href: '#'
        onClick: (e) =>
          e.preventDefault()
          console.log @props.item
      ,
        DOM.em
          className: 'glyphicon glyphicon-tag'
