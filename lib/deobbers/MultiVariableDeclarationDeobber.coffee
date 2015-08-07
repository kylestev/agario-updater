Deobber = require('./Deobber')

class MultiVariableDeclarationDeobber extends Deobber
  constructor: () ->
    super

  enter: (node, parent) ->
    # if node.type == 'LogicalExpression'
    #   console.log node


module.exports = MultiVariableDeclarationDeobber
