_ = require('lodash')
Identifier = require('./Identifier')
Helper = require('./Helper')

class CellIdentifier extends Identifier
  constructor: () ->
    super 'Cell Identifier'

  visit: (tree, analyzer) ->
    clazz = _.find tree, (node) ->
      Helper.matchFunctionParameterCountBetween node, 6, 7

    if clazz

      # tell the parent that we have identified a class.
      # this is the Cell constructor therefore we have found the Cell class.
      hook = @identifyClass 'Cell', clazz.id.name

      # identify any other parameters that we can from this context.
      # constructors are usually a great way to identify field members.
      @identifyClassMembers clazz

      # inject a doc block comment into the tree so when we generate
      # the source, we can see where this hook was identified from
      Helper.injectClassHookComment clazz, hook

  identifyClassMembers: (node) ->
    memberOrder = ['id', 'x', 'y', 'size', 'color']
    Helper.extractConstructorParameters node, memberOrder, (name, field, node) =>
      hook = @identifyField 'Cell', name, field

      Helper.injectFieldHookComment node, hook


module.exports = new CellIdentifier
