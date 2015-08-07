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
        console.log 'gameCanvas found'
        @identifyCanvasEvents cls, hook

    @emitter.on 'gameCanvas.event', (eventName, ast) ->
      console.log 'located gameCanvas event:', eventName

  identifyCanvasEvents: (cls, canvasHook) ->
    estraverse.traverse @tree, {
      enter: (node, parent) =>
        if node.type == 'AssignmentExpression' and _.has node.left, 'object'
          if not _.has @inputEvents, node.left.property.name
            return undefined
          func = _.clone node.right
          func.id = { name: node.left.object.name + '.' + node.left.property.name }
          Helper.injectFunctionHookComment node, {
            name: 'gameCanvas.' + node.left.property.name
            type: 'EventHook'
            func: func
            params: { event: 'a' }
          }
          if node.right.body isnt undefined
            Helper.injectCallback node.right, 'Callbacks.' + @inputEvents[node.left.property.name]
          @emitter.emit 'gameCanvas.event', node.left.property.name, node.right
    }

  visit: (root, tree) ->
    @tree = tree


module.exports = new CanvasEventIdentifier
