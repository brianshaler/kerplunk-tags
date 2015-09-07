_ = require 'lodash'
Promise = require 'when'

hashPattern = /(^|\s)#([-A-Za-z0-9_]+)(\b)/gi

module.exports = (System) ->
  Identity = System.getModel 'Identity'
  ActivityItem = System.getModel 'ActivityItem'

  addTag = (data) ->
    {item, parameter} = data
    tag = "tag:#{parameter.toLowerCase()}"
    Characteristic.getOrCreate tag
    .then (characteristic) ->
      item.attributes = {} unless item.attributes
      unless item.attributes?.characteristic?.length > 0
        item.attributes.characteristic = []
      item.attributes.characteristic.push characteristic._id
      item

  getTag = (tagText) ->
    tag = "tag:#{tagText.toLowerCase()}"
    Characteristic.getOrCreate tag

  removeTag = (data) ->
    {item, parameter} = data
    tag = "tag:#{parameter.toLowerCase()}"
    mpromise = Characteristic
    .where
      text: tag
    .findOne()
    Promise(mpromise).then (characteristic) ->
      return item unless characteristic
      return item unless item.attributes?.characteristic?.length > 0
      item.attributes.characteristic = _.filter item.attributes?.characteristic, (cid) ->
        String(cid) != String(characteristic._id)
      item

  preSave = (item) ->
    tags = []
    hashPattern.lastIndex = 0
    while match = hashPattern.exec item.message
      tags.push match[2]
    return item unless tags.length > 0
    promise = Promise()
    for tag in tags
      do (tag) ->
        promise = promise.then ->
          addTag
            item: item
            parameter: tag
    promise.then -> item

  routes:
    admin:
      '/admin/item/:id/tags/add/:tag': 'addTag'
      '/admin/item/:id/tags/remove/:tag': 'removeTag'

  handlers:
    addTag: (req, res, next) ->
      {id, tag} = req.params
      ActivityItem
      .where
        _id: id
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        addTag
          item: item
          parameter: tag
        .then ->
          item.markModified 'attributes'
          item.save (err) ->
            return next err if err
            System.do 'activityItem.populate', item
            .then ->
              if item.toObject
                item = item.toObject()
              delete item.data
              res.render 'kerplunk-activityitem:show',
                item: item
    removeTag: (req, res, next) ->
      {id, tag} = req.params
      ActivityItem
      .where
        _id: id
      .findOne (err, item) ->
        return next err if err
        return next() unless item
        removeTag
          item: item
          parameter: tag
        .then ->
          item.markModified 'attributes'
          item.save (err) ->
            return next err if err
            res.render 'kerplunk-activityitem:show',
              item: item

  globals:
    public:
      activityItem:
        controls:
          'kerplunk-tags:tagControl': true
      editStreamConditionOptions:
        hasTag:
          description: 'is tagged...'
          show_text: true
          where: 'tag.query.hasTag'
        doesNotHaveTag:
          description: 'does not have the tag...'
          show_text: true
          where: 'tag.query.doesNotHaveTag'

  events:
    activityItem:
      save:
        pre: preSave
    tag:
      query:
        hasTag:
          do: (data) ->
            getTag data.parameter
            .then (characteristic) ->
              data.query['attributes.characteristic'] = characteristic?._id
              data
        doesNotHaveTag:
          do: (data) ->
            getTag data.parameter
            .then (characteristic) ->
              data.query['attributes.characteristic'] =
                '$ne': characteristic?._id
              data
