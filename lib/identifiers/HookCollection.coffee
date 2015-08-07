_ = require('lodash')
events = require('events')
EVENTS = new events.EventEmitter()

expand_unknown_params = (params) ->
  '(' + _.values(params).join(', ') + ')'

expand_known_params = (params) ->
  '(' + _.keys(params).join(', ') + ')'

class HookCollection
  constructor: (@hooks, @emitter) ->
  
  addHook: (hook) ->
    @hooks.push hook
    @emitter.emit 'hook.added', hook
    return hook

  addField: (clazz, field) ->
    match = _.find @hooks, { type: 'ClassHook', name: clazz }
    if not match
      throw 'class not found: ' + clazz
    match.fields.push field
    @emitter.emit 'field.added', match, field
    return field

  getField: (clazz, name) ->
    match = _.find @hooks, { type: 'ClassHook', name: clazz }
    _.find match.fields, { name: name }

  identifyField: (clazz, name, field) ->
    @addField clazz, {
      type: 'FieldHook'
      name: name
      field: field
    }

  identifyClass: (name, clazz) ->
    @addHook {
      type: 'ClassHook'
      name: name
      class: clazz
      fields: []
      methods: []
    }

  identifyMethod: (name, func, params) ->
    @addHook {
      type: 'MethodHook'
      name: name
      func: func
      params: params or {}
    }

  identifyFunction: (name, func, params) ->
    @addHook {
      type: 'FunctionHook'
      name: name
      func: func
      params: params or {}
    }

  modScript: () ->
    classes = _.filter @hooks, { type: 'ClassHook' }

    clazz = _.first classes
    _.each classes, (clazz) ->
      identified = if clazz['class'] == null then 'BROKEN' else clazz['class']
      console.log '∫', clazz.name, '→', identified

      # extract all `FieldHook` types from hooks
      for ignored, hook of clazz.fields
        console.log '  ✔', hook.name, '→', hook.field.name

    for ig, func of _.filter @hooks, { type: 'FunctionHook' }
      identified = if func.func == null then 'BROKEN' else func.func.id.name + expand_unknown_params(func.params)
      console.log '•', func.name + expand_known_params(func.params), '→', identified


module.exports = new HookCollection [], EVENTS
