_ = require('lodash')
Identifier = require('./Identifier')
Helper = require('./Helper')

class NodeIdentifier extends Identifier
  constructor: () ->
    super 'Node Identifier'

  visit: (tree, analyzer) ->
    clazz = _.find tree, (node) ->
      Helper.matchFunctionParameterCount node, 5

    if clazz
      hook = @identifyClass 'Node', clazz.id.name
      @identifyClassMembers clazz
      Helper.injectClassHookComment clazz, hook

  identifyClassMembers: (node) ->
    memberOrder = ['left', 'top', 'width', 'height', 'depth']
    Helper.extractConstructorParameters node, memberOrder, (name, field, node) =>
      hook = @identifyField 'Node', name, field
      Helper.injectFieldHookComment node, hook


module.exports = new NodeIdentifier
