_ = require('lodash')
esprima = require('esprima')
Deobber = require('./Deobber')

FALSE_LITERAL = esprima.parse('false').body[0].expression;
TRUE_LITERAL = esprima.parse('true').body[0].expression;

NOT_ZERO = esprima.parse('!0').body[0].expression;
NOT_ONE = esprima.parse('!1').body[0].expression;

class UnpackLogicalExpressionDeobber extends Deobber

  complement: (ast) ->
    return { type: 'UnaryExpression', operator: '!', prefix: true, argument: ast }

  exprStatement: (ast) ->
    return { type: 'ExpressionStatement', expression: ast }

  exprConsequent: (ast, block = false) ->
    expr = @exprStatement ast

    if block
      return {
        type: 'BlockStatement'
        body: [ expr ]
      }

    expr

  enter: (node, parent) =>
    if _.eq NOT_ZERO, node
      return TRUE_LITERAL

    if _.eq NOT_ONE, node
      return FALSE_LITERAL

    if node.type == 'ExpressionStatement'
      expr = node.expression
      if expr.type == 'LogicalExpression'
        return {
          type: 'IfStatement'
          test: if expr.operator == '&&' then expr.left else @complement expr.left
          consequent: @exprConsequent expr.right, true
          alternate: null
        }

      if expr.type == 'ConditionalExpression'
        r = {
          type: 'IfStatement'
          test: expr.test
          consequent: @exprConsequent expr.consequent, true
          alternate: @exprConsequent expr.alternate
        }
        return r


module.exports = UnpackLogicalExpressionDeobber
