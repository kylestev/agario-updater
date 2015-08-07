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
        func = null
        estraverse.traverse @tree, {
          enter: (node, parent) ->
            if node.type == 'FunctionDeclaration'
              func = node

            if node.type == 'ExpressionStatement' and node.expression.type == 'CallExpression' and node.expression.callee.type == 'MemberExpression'
              expr = node.expression
              if expr.callee.object.name == 'console' and expr.arguments.length == 1 and expr.arguments[0].value == 'socket close'
                hook = that.identifyFunction 'WebSocketCloseHandler', func
                Helper.injectFunctionHookComment func, hook

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

              injectPacketComment = (_case, title, link) ->
                Helper.injectCommentBlock _case.consequent[0], ' ' + title + ' | ' + link + ' '

              for idx, _case of func.body.body[3].cases
                switch _case.test.value
                  when 16
                    injectPacketComment _case, 'World Update', 'http://agar.gcommer.com/index.php?title=Protocol#World_Update_.28opcode_16.29'
                    injectPacketCallback('Callback.Packets.onWorldUpdate', [], _case)
                  when 17
                    injectPacketComment _case, 'View Update', 'http://agar.gcommer.com/index.php?title=Protocol#View_Update_.28opcode_17.29'
                    injectPacketCallback('Callback.Packets.onViewUpdate', ['viewX', 'viewY', 'viewZoom'], _case)
                  when 20
                    injectPacketComment _case, 'Reset', 'http://agar.gcommer.com/index.php?title=Protocol#Reset_.28opcode_20.29'
                    injectPacketCallback('Callback.Packets.onReset', [], _case)
                  when 21
                    injectPacketComment _case, 'Draw Debug Line', 'http://agar.gcommer.com/index.php?title=Protocol#Draw_debug_line_.28opcode_21.29'
                    injectPacketCallback('Callback.Packets.onDebugLine', ['debugLineX', 'debugLineY'], _case)
                  when 32
                    injectPacketComment _case, 'Owns Blob', 'http://agar.gcommer.com/index.php?title=Protocol#Owns_blob_.28opcode_32.29'
                    injectPacketCallback('Callback.Packets.onOwnsBlob', [], _case)
                  when 49
                    injectPacketComment _case, 'FFA Leaderboard', 'http://agar.gcommer.com/index.php?title=Protocol#FFA_Leaderboard_.28opcode_49.29'
                    injectPacketCallback('Callback.Packets.onFFALeaderboard', [], _case)
                  when 50
                    injectPacketComment _case, 'Team Leaderboard', 'http://agar.gcommer.com/index.php?title=Protocol#Team_Leaderboard_.28opcode_50.29'
                    injectPacketCallback('Callback.Packets.onTeamLeaderboard', [], _case)
                  when 64
                    injectPacketComment _case, 'Game Area Size', 'http://agar.gcommer.com/index.php?title=Protocol#Game_area_size_.28opcode_64.29'
                    injectPacketCallback('Callback.Packets.onGameAreaSize', ['gameMinX', 'gameMinY', 'gameMaxX', 'gameMaxY'], _case)
                  when 81
                    injectPacketComment _case, 'Blob Experience Info', 'http://agar.gcommer.com/index.php?title=Protocol#Blob_experience_info_.28opcode_81.29'
                    injectPacketCallback('Callback.Packets.onBlobExperienceInfo', [], _case)

              this.break()
        }

  visit: (@root, @tree) ->


module.exports = new PacketHandlerIdentifier
