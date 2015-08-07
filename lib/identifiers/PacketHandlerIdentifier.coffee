_ = require('lodash')
Identifier = require('./Identifier')
Helper = require('./Helper')
estraverse = require('estraverse')

class PacketHandlerIdentifier extends Identifier
  constructor: () ->
    super 'PacketHandler Identifier'

  boot: () ->
    super
    @emitter.on 'hook.added', (hook) =>
      if (_.matches { type: 'ClassHook', name: 'Init' })(hook)
        that = @
        estraverse.traverse @tree, {
          enter: (node, parent) ->
            if node.type == 'NewExpression' and node.callee.name == 'DataView' and node.arguments[0].type == 'MemberExpression'
              hook = that.identifyFunction 'PacketHandler', { id: name: parent.callee.name }, { buffer: 'a' }
              func = Helper.findFunction(that.root, parent.callee.name)
              Helper.injectFunctionHookComment func, hook
              injectPacketCallback = (callbackPath, fields, _case) ->
                params = []
                count = 0
                _.some _.filter(_case.consequent, { type: 'ExpressionStatement', expression: operator: '=' }), (ast) ->
                  if count >= fields.length
                    return true

                  hook = that.identifyField 'Init', fields[count++], ast.expression.left
                  params.push ast.expression.left.name
                  Helper.injectFieldHookComment ast, hook

                  return false
                Helper.injectTailCallback _case.consequent, callbackPath, params

              for idx, _case of func.body.body[3].cases
                switch _case.test.value
                  when 17
                    injectPacketCallback('Callback.Packets.onViewUpdate', ['viewX', 'viewY', 'viewZoom'], _case)
                  when 21
                    injectPacketCallback('Callback.Packets.onDebugLine', ['debugLineX', 'debugLineY'], _case)
                  when 64
                    injectPacketCallback('Callback.Packets.onGameAreaSize', ['gameMinX', 'gameMinY', 'gameMaxX', 'gameMaxY'], _case)

              this.break()
        }

  visit: (@root, @tree) ->


module.exports = new PacketHandlerIdentifier
