_ = require('lodash')
Identifier = require('./Identifier')
Helper = require('./Helper')

class SendCommandIdentifier extends Identifier
  constructor: () ->
    super 'SendCommand Identifier'

  boot: () ->
    super
    @emitter.on 'hook.added', (hook) =>
      if (_.matches { type: 'FunctionHook', name: 'FindGame' })(hook)
        @identifyConnect hook

  visit: (tree) ->
    @identifyIsConnected tree
    @identifySendCommand tree
    @identifyInputEvents tree

  identifyInputEvents: (tree) ->
    matches = _.filter tree, (node) ->
      Helper.matchType 'FunctionDeclaration'

    initFunc = matches[0]

    hook = @identifyClass 'Init', initFunc.id.name
    Helper.injectClassHookComment initFunc, hook

    try
      @identifyPlayerStatistics tree, initFunc
      @identifyMouseMove tree, initFunc
      @identifyKeyDown tree, initFunc

      @identifyFindGame matches
      @identifyGameOver matches
      @identifySetGameMode matches
      @identifyRenderInternational matches
    catch error
      console.error error.message
      throw error

  identifyCachedCanvas: (funcs) ->
    clazz = _.find funcs, (func) -> Helper.matchFunctionParameterCount func, 4

    if clazz
      canvasHook = @identifyClass 'CachedCanvas', clazz.id.name
      fieldMembers = ['size', 'color', 'stroke', 'strokeColor']
      Helper.extractConstructorParameters clazz, fieldMembers, (name, field, node) =>
        hook = @identifyField 'CachedCanvas', name, field
        Helper.injectFieldHookComment node, hook
      Helper.injectClassHookComment clazz, canvasHook
    else
      @identifyClass 'CachedCanvas', null

  identifyCanvasContext: (tree, initFunc) ->
    canvasField = @getField 'Init', 'canvas'
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
        hook = @identifyField 'Init', 'canvasContext', node.expression.left
        Helper.injectFieldHookComment node, hook
        return true

  identifyCanvas: (tree, initFunc) ->
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
        hook = @identifyField 'Init', 'canvas', node.expression.left
        Helper.injectFieldHookComment node, hook
        return true

  identifyRenderInternational: (funcs) ->
    match = _.find funcs, (func) ->
      if not Helper.matchFunctionParameterCount(func, 1) 
        return false

      return _.some func.body.body, (node) ->
        if not Helper.matchType(node, 'ReturnStatement') or not Helper.matchType(node.argument, 'LogicalExpression')
          return
        return true

    if match
      hook = @identifyFunction 'RenderInternationalText', match, { identifier: match.params[0].name }
      Helper.injectCallback match, 'Callback.RenderIntlText'
      Helper.injectFunctionHookComment match, hook
    else
      @identifyFunction 'RenderInternationalText', null

  identifyFindGame: (funcs) ->
    match = _.find funcs, (func) ->
      if not Helper.matchFunctionParameterCount(func, 0)
        return false

      return _.some func.body.body, (node) ->
        if (_.matches { expression: { arguments: [{ type: 'Literal', value: 'http://m.agar.io/findServer' }] } })(node)
          return true

    if match
      hook = @identifyFunction 'FindGame', match
      Helper.injectFunctionHookComment match, hook
    else
      @identifyFunction 'FindGame', null

  identifyConnect: (hook) ->
    # TODO: finish
    match = _.first(_.filter hook.func.body.body, {
      type: 'ExpressionStatement', expression: {
        type: 'CallExpression'
        callee: { property: { name: 'ajax' } }
        arguments: [{ type: 'ObjectExpression' }] }
    })

    if not match
      return @identifyFunction 'Connect', null

    objDef = match.expression.arguments[1]

  identifyGameOver: (funcs) ->
    found = null
    match = _.find funcs, (func) ->
      if not Helper.matchFunctionParameterCount(func, 1)
        return false

      if not Helper.matchType func.body.body[0], 'IfStatement'
        return false

      block = func.body.body[0].consequent.body[0]
      if not Helper.matchType(block, 'ExpressionStatement') or not Helper.matchType(block.expression, 'SequenceExpression')
        return false

      expr = block.expression.expressions[0]
      if not Helper.matchType(expr, 'CallExpression') or expr.callee.object.arguments.length != 1
        return false

      args = expr.callee.object.arguments
      if args[0].value == '#adsBottom'
        found = func
        return true

    if match
      hook = @identifyFunction 'GameOver', match, { animationDuration: match.params[0].name }
      Helper.injectFunctionHookComment match, hook
    else
      @identifyFunction 'GameOver', null

  identifySetGameMode: (funcs) ->
    match = _.find funcs, (func) ->
      if not Helper.matchFunctionParameterCount(func, 1)
        return false

      return (_.matches {
        expression: { callee: { object: { arguments: [ { type: 'Literal', value: '#helloContainer' } ] } } }
      })(func.body.body[0])
    
    if match
      hook = @identifyFunction 'SetGameMode', match, { gameMode: match.params[0].name }
      Helper.injectFunctionHookComment match, hook
      Helper.injectCallback match, 'Callbacks.onGameModeChange'
    else
      @identifyFunction 'SetGameMode', null

  identifyKeyDown: (tree, initFunc) ->
    _.find initFunc.body.body, (node) =>
      if not _.matches({
          type: 'ExpressionStatement', expression: {
            type: 'AssignmentExpression'
            left: { type: 'MemberExpression', object: {}, property: { name: 'onkeydown' } }
            right: { type: 'FunctionExpression' } }
        })(node)
        return false

      methodGuts = node.expression.right.body.body

      if _.matches({
        type: 'ExpressionStatement', expression: {
          type: 'LogicalExpression', operator: '||'
          left: {
            type: 'LogicalExpression', operator: '||'
            left: { type: 'BinaryExpression', operator: '!=', left: { type: 'Literal', value: 32 } } } }
      })(methodGuts[0])
        hook = @identifyField 'Init', 'spaceKeyDown', methodGuts[0].expression.left.right
        Helper.injectFieldHookComment methodGuts[0], hook

      if _.matches({
        type: 'ExpressionStatement'
        expression: {
          type: 'LogicalExpression', operator: '||'
          left: {
            type: 'LogicalExpression', operator: '||'
            left: {
              type: 'BinaryExpression', operator: '!='
              left: { type: 'Literal', value: 81 } } } }
      })(methodGuts[1])
        hook = @identifyField 'Init', 'cachedSkin', methodGuts[1].expression.left.right
        Helper.injectFieldHookComment methodGuts[1], hook

      if _.matches({
        type: 'ExpressionStatement', expression: {
          type: 'LogicalExpression', operator: '||'
          left: {
            type: 'LogicalExpression', operator: '||'
            left: {
              type: 'BinaryExpression', operator: '!='
              left: { type: 'Literal', value: 87 } } } }
      })(methodGuts[2])
        hook = @identifyField 'Init', 'wKeyDown', methodGuts[2].expression.left.right
        Helper.injectFieldHookComment methodGuts[2], hook

  identifyMouseMove: (tree, initFunc) ->
    canvasField = @getField 'Init', 'gameCanvas'
    _.find initFunc.body.body, (node) =>
      if not _.matches({
          type: 'ExpressionStatement', expression: {
            type: 'AssignmentExpression'
            left: { type: 'MemberExpression', object: canvasField.field , property: { name: 'onmousemove' } }
            right: { type: 'FunctionExpression' } }
        })(node)
        return false

      methodGuts = node.expression.right.body.body

      count = 0
      hookNames = ['canvasMouseX', 'canvasMouseY']
      for idx, expr of methodGuts
        if count >= hookNames.length
          break

        if _.matches({
          type: 'ExpressionStatement', expression: { type: 'AssignmentExpression', operator: '=' }
        })(expr)
          hook = @identifyField 'Init', hookNames[count++], expr.expression.left
          Helper.injectFieldHookComment expr.expression.left, hook

      hook = @identifyFunction 'UpdatePos', Helper.findFunction tree, methodGuts[methodGuts.length - 1].expression.callee.name
      Helper.injectFunctionHookComment methodGuts[methodGuts.length - 1], hook

  identifyPlayerStatistics: (tree, initFunc) ->
    _.each initFunc.body.body, (node) =>
      if not Helper.matchCaller node, 'setInterval'
        return

      params = Helper.extractCallArguments node.expression
      if params.length != 2
        return

      [func, interval] = params
      if Helper.matchType(func, 'Identifier') and (_.matches { type: 'Literal', value: 180000 })(interval)
        realFunc = Helper.findFunction tree, func.name
        hook = @identifyFunction 'PlayerStatistics', realFunc
        Helper.injectFunctionHookComment node, hook
      else
        console.log @hooks.hooks
        if _.size(_.filter(@hooks.hooks, { name: 'PlayerStatistics' })) != 1
          @identifyFunction 'PlayerStatistics', null

  identifySendCommand: (tree) ->
    isConnected = _.find @hooks.hooks, { name: 'IsConnected' }
    func = _.find tree, (node) ->
      if not Helper.matchFunctionParameterCount node, 1
        return false

      stmt = _.get(node, 'body.body[0]', false)
      if stmt.type != 'IfStatement' or stmt.test.type != 'CallExpression'
        return false

      return stmt.test.callee.name == isConnected.func.id.name

    if func
      hook = @identifyFunction 'SendCommand', func, { cmd: func.params[0].name }
      Helper.injectCallback func, 'Callback.onCommandQueued'
      Helper.injectFunctionHookComment func, hook
    else
      @identifyFunction 'SendCommand', null

  identifyIsConnected: (tree) ->
    func = _.find tree, (node) ->
      if not Helper.matchFunctionParameterCount node, 0
        return false
      node.body.body[0].type == 'ReturnStatement'

    if func
      @identifyFunction 'IsConnected', func
    else
      @identifyFunction 'IsConnected', null


module.exports = new SendCommandIdentifier
