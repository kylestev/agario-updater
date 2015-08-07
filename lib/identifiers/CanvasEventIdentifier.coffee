_ = require('lodash')
Helper = require('./Helper')
estraverse = require('estraverse')
Identifier = require('./Identifier')

class CanvasEventIdentifier extends Identifier
  constructor: () ->
    super 'CanvasEvent Identifier'
    @inputEvents = {
      onblur: 'onBlur', onkeyup: 'onKeyUp', onkeydown: 'onKeyDown'
      onmousemove: 'onMouseMove', onmousewheel: 'onMouseWheel'
      onmouseup: 'onMouseUp', onmousedown: 'onMouseDown'
    }

  boot: () ->
    @emitter.on 'field.added', (cls, hook) =>
      if hook.name == 'gameCanvas'
        @identifyCanvasEvents cls, hook

    @emitter.on 'gameCanvas.event', (eventName, ast) =>
      if eventName == 'onmousewheel'
        @identifyWheelHandler ast

  identifyCanvasEvents: (cls, canvasHook) ->
    estraverse.traverse @tree, {
      enter: (node, parent) =>
        if node.type == 'AssignmentExpression' and _.has node.left, 'object'
          if not _.has @inputEvents, node.left.property.name
            return undefined
          func = _.clone node.right
          func.id = { name: node.left.object.name + '.' + node.left.property.name }
          boundTo = if canvasHook.field.name == node.left.object.name then canvasHook.name else 'window'
          Helper.injectFunctionHookComment node, {
            name: boundTo + '.' + node.left.property.name
            type: 'EventHook'
            func: func
            params: { event: 'a' }
          }
          if node.right.body isnt undefined
            Helper.injectCallback node.right, 'Callbacks.' + @inputEvents[node.left.property.name]
          @emitter.emit boundTo + '.event', node.left.property.name, node.right
    }

  identifyWheelHandler: (ast) ->
    func = Helper.findFunction @root, ast.name
    if func
      hook = @identifyFunction 'WheelHandler', func, { event: func.params[0].name }
      _.find @root, (node) =>
        if not Helper.matchType(node, 'FunctionDeclaration') or node.id.name != func.id.name or node.params.length != func.params.length
          return

        Helper.injectFunctionHookComment node, hook
        return true
    else
      @identifyFunction 'WheelHandler', null

  visit: (root, tree) ->
    @root = root
    @tree = tree


module.exports = new CanvasEventIdentifier
