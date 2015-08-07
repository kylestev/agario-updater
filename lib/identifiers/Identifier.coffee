_ = require('lodash')
HookCollection = require('./HookCollection')

class Identifier
  constructor: (@name) ->
    @hooks = HookCollection
    @emitter = @hooks.emitter

  boot: () ->
    # empty
  
  getField: (params...) ->
    @hooks.getField params...
  
  identifyClass: (params...) ->
    @hooks.identifyClass params...
  
  identifyField: (params...) ->
    @hooks.identifyField params...
  
  identifyMethod: (params...) ->
    @hooks.identifyMethod params...
  
  identifyFunction: (params...) ->
    @hooks.identifyFunction params...
  
  afterVisit: () ->
    @analysis_end = _.now()
  
  beforeVisit: () ->
    @analysis_start = _.now()

  visit: (tree, analyzer) ->
    # empty


module.exports = Identifier
