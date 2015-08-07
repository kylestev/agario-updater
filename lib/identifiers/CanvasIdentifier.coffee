_ = require('lodash')
Identifier = require('./Identifier')
Helper = require('./Helper')
estraverse = require('estraverse')

class CanvasIdentifier extends Identifier
  constructor: () ->
    super 'Canvas Identifier'

  boot: () ->
    super
    @emitter.on 'hook.added', (hook) =>
      if (_.matches { type: 'ClassHook', name: 'Init' })(hook)
        @identifyCanvasMembers hook

  visit: (@root, @tree) ->
    cachedCanvasName = null
    estraverse.traverse @tree, {
      enter: (node, parent) ->
        if (_.matches { type: 'NewExpression', arguments: [{ value: '#FFFFFF' }, { value: '#000000' }] })(node)
          cachedCanvasName = node.callee.name
          this.break()
    }
    cachedCanvas = _.find _.filter(@root, (node) -> Helper.matchType 'FunctionDeclaration'), { id: name: cachedCanvasName }
    @identifyCachedCanvas cachedCanvas

  identifyCanvasMembers: (cls) ->
    initFunc = _.find @root, {
      type: 'FunctionDeclaration'
      id: { name: cls['class'] } }
    try
      @identifyCanvas initFunc
      @identifyCanvasContext initFunc
    catch error
      throw error

  identifyCachedCanvas: (clazz) ->
    if clazz
      canvasHook = @identifyClass 'CachedCanvas', clazz.id.name
      fieldMembers = ['size', 'color', 'stroke', 'strokeColor']
      Helper.extractConstructorParameters clazz, fieldMembers, (name, field, node) =>
        hook = @identifyField 'CachedCanvas', name, field
        Helper.injectFieldHookComment node, hook
      Helper.injectClassHookComment clazz, canvasHook
    else
      @identifyClass 'CachedCanvas', null

  identifyCanvasContext: (initFunc) ->
    canvasField = @getField 'Init', 'gameCanvas'
    _.find initFunc.body.body, (node) =>
      if not _.matches({
          type: 'ExpressionStatement', expression: {
            type: 'AssignmentExpression'
            right: { type: 'CallExpression', callee: { object: canvasField.field } } }
        })(node)
        return false

      params = Helper.extractCallArguments node.expression.right
      if params.length != 1
        return false

      [canvas] = params
      if _.matches({ type: 'Literal', value: '2d' })(canvas)
        hook = @identifyField 'Init', 'gameCanvasContext', node.expression.left
        Helper.injectFieldHookComment node, hook
        return true

  identifyCanvas: (initFunc) ->
    _.find initFunc.body.body, (node) =>
      if not _.matches({
          type: 'ExpressionStatement', expression: {
            type: 'AssignmentExpression', right: {
              type: 'AssignmentExpression', right: { type: 'CallExpression' } } }
        })(node)
        return false

      params = Helper.extractCallArguments node.expression.right.right
      if params.length != 1
        return false

      [canvas] = params
      if _.matches({ type: 'Literal', value: 'canvas' })(canvas)
        hook = @identifyField 'Init', 'gameCanvas', node.expression.left
        Helper.injectFieldHookComment node, hook
        return true


module.exports = new CanvasIdentifier
