_ = require('lodash')
estraverse = require('estraverse')

Helper = require('./Helper')
Identifier = require('./Identifier')

class QuadTreeIdentifier extends Identifier
  constructor: () ->
    super 'QuadTree Identifier'

  visit: (@root, @tree) ->
    @identifyQuadTreeFactory @root
    @identifyQuadTreeFactoryPrototype @tree

  identifyQuadTreeFactoryPrototype: (tree) ->
    that = @
    qtf = @quadTreeFactory
    estraverse.traverse(tree, {
      enter: (node, parent) ->
        if node.type == 'VariableDeclarator' and node.id.name == qtf
          that.identifyMethod 'QuadTreeFactory', '_unknown', node.init.properties[0].value
          @break()
    })

  identifyQuadTreeFactory: (tree) ->
    _.some tree, (node) =>
      if not Helper.matchType(node, 'FunctionDeclaration') or not Helper.matchType node.body, 'BlockStatement'
        return
      if not (_.matches {
        type: 'BlockStatement', body: [ {
            type: 'IfStatement', test: {
              type: 'BinaryExpression', operator: '>'
              left: { type: 'Literal', value: 0.4 } } } ]
      })(node.body)
        return
      _.some node.body.body[0].alternate.body, (node) =>
        if not Helper.matchType node, 'ExpressionStatement'
          return
        @quadTreeFactory = node.expression.right.callee.object.name
        @identifyClass 'QuadTreeFactory', node.expression.right.callee.object.name
        return true
      return true


module.exports = new QuadTreeIdentifier
