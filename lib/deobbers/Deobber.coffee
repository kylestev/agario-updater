# AbstractTransform = require('../transforms/AbstractTransform')
estraverse = require('estraverse')

class Deobber # extends AbstractTransform
  constructor: () ->
    # super @tree

  enter: (node, parent) ->
    # empty

  leave: (node, parent) ->
    # empty

  transform: (@tree) ->
    estraverse.replace(@tree, {
        enter: @enter
        leave: @leave
    })


module.exports = Deobber
