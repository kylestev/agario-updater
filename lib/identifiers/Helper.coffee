_ = require('lodash')
esprima = require('esprima')

class Helper
  constructor: () ->
    @comments = []
    @callbacks = []
  
  matchFunctionParameterCount: (node, count) ->
    node.type == 'FunctionDeclaration' and node.params.length == count
  
  matchFunctionParameterCountBetween: (node, lower, upper) ->
    node.type == 'FunctionDeclaration' and node.params.length >= lower and node.params.length <= upper

  matchType: (node, type) ->
    node.type == type

  matchExpressionType: (node, type) ->
    @matchType(node, 'ExpressionStatement') and @matchType(node.expression, type)

  matchAssignmentExpression: (node, side, type) ->
    if not @matchExpressionType node, 'AssignmentExpression'
      return false
    @matchType node.expression[side], type

  matchCaller: (node, caller) ->
    if not @matchExpressionType node, 'CallExpression'
      return false
    node.expression.callee.name == caller

  extractAssignmentMember: (node, side) ->
    node.expression[side]

  extractCallArguments: (node) ->
    node.arguments

  extractConstructorParameters: (node, paramNames, cb) ->
    count = 0
    for idx, expr of node.body.body
      if count >= paramNames.length
        break

      if (_.matches {
        type: 'IfStatement'
        test: { type: 'Identifier' }
        consequent: {
          type: 'BlockStatement'
          body: [
            {
              type: 'ExpressionStatement'
              expression: {
                type: 'AssignmentExpression'
                left: {
                  object: { type: 'ThisExpression' } } } } ] }
      })(expr)
        cb paramNames[count], expr.consequent.body[0].expression.left.property, expr.consequent.body[0]
        count++
        continue

      if (_.matches {
        expression: {
          type: 'LogicalExpression', operator: '&&'
          right: {
            type: 'AssignmentExpression'
            left: { type: 'MemberExpression', object: { type: 'ThisExpression' } } }
        }
      })(expr)
        member = expr.expression.right.left.property.name
        param = expr.expression.right.right.name
        # node.body.body[idx] = esprima.parse('if(' + param + '){this.' + member + '=' + param+'}').body[0]
        cb paramNames[count], { type: 'Identifier', name: member }, node.body.body[idx]
        count++
        continue

      if (_.matches {
        type: 'ExpressionStatement', expression: {
          type: 'AssignmentExpression', operator: '='
          left: {
            type: 'MemberExpression', object: { type: 'ThisExpression' } } }
      })(expr)
        if (_.matches {
          right: {
            type: 'AssignmentExpression'
            left: {
              object: { type: 'ThisExpression' } } }
        })(expr.expression)
          cb paramNames[count],  expr.expression.right.left.property, expr
          # double assignment ie: `this.b = this.x = x;`
          # cb paramNames[count],  expr.expression.left.property, expr
          count++
        else
          cb paramNames[count], expr.expression.left.property, expr
          count++
        continue
      else
        continue

      console.log expr.expression
      if not @matchAssignmentExpression expr, 'left', 'MemberExpression'
        continue

      leftSide = @extractAssignmentMember expr, 'left'
      if not leftSide.object or not @matchType leftSide.object, 'ThisExpression'
        continue

      cb paramNames[count], leftSide.property, expr

      count += 1

  findFunction: (tree, name) ->
    _.find tree, (node) =>
      if not @matchType node, 'FunctionDeclaration'
        return false

      if node.id and node.id.name == name
        return node

  stopWatch: (func) ->
    start_time = _.now()
    func()
    end_time = _.now()
    (end_time - start_time) / 1000.0

  parameterize: (obj) ->
    (_.map(obj, (value, key) -> (key + '="' + value + '"'))).join(', ')

  injectDefered: (config) ->
    if config.injectCallbacks
      _.each @callbacks, (cb) -> cb()
    if config.injectComments
      _.each @comments, (cb) -> cb()

  injectCommentBlock: (node, comment) ->
    @comments.push () ->
      if not node.leadingComments
        node.leadingComments = []
      node.leadingComments.push({ type: 'Block', value: comment })

  injectCommentIdentifier: (node, info, hook) ->
    info = _.merge { name: hook.name }, info

    @injectCommentBlock node, '* @' + hook.type + '(' + @parameterize(info) + ') '

  injectFieldHookComment: (node, hook) ->
    @injectCommentIdentifier node, { field: hook.field.name }, hook

  injectFunctionHookComment: (node, hook) ->
    info = { func: hook.func.id.name }
    if _.size(hook.params) > 0
      info.params = _.keys hook.params

    @injectCommentIdentifier node, info, hook

  injectClassHookComment: (node, hook) ->
    info = { 'class': hook['class'] }
    info.params = _.map hook.fields, (field) -> field.name
    @injectCommentIdentifier node, info, hook

  injectCallback: (func, callbackPath) ->
    @callbacks.push () =>
      params = _.pluck func.params, 'name'

      callback = esprima.parse(callbackPath + '(' + params.join(', ') + ')')
      @injectCommentIdentifier callback.body[0], {}, { type: 'Callback', name: callbackPath.split('.')[1] }
      # reverse the order of the 
      _.each callback.body.reverse(), (node) ->
        func.body.body.unshift node

  injectTailCallback: (ast, callbackPath, params) ->
    @callbacks.push () =>
      callback = esprima.parse(callbackPath + '(' + params.join(', ') + ')')
      name = callbackPath.substring(callbackPath.indexOf('.') + 1)
      injectLocation = _.size _.reject(ast, { type: 'BreakStatement' })
      @injectCommentIdentifier callback.body[0], {}, { type: 'Callback', name: name }
      _.each callback.body.reverse(), (node) ->
        ast.splice injectLocation, 0, node

module.exports = new Helper
