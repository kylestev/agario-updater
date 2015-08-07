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
    fld = _.find match.fields, { name: field.name }
    if fld
      return fld
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
    classes = _.sortBy _.filter(@hooks, { type: 'ClassHook' }), 'name'

    console.log 'Identified Classes'
    _.each classes, (clazz) ->
      identified = if clazz['class'] == null then 'BROKEN' else clazz['class']
      console.log ' ∫', clazz.name, '→', identified

      maxFieldLength = _.last(_.sortBy(_.map(clazz.fields, (f) -> f.name.length))) + 1
      # extract all `FieldHook` types from hooks
      for ignored, hook of _.sortBy clazz.fields, 'name'
        console.log '   ✔', hook.name, (new Array(Math.max(maxFieldLength - hook.name.length, 0)).join ' '), '→', hook.field.name
      console.log ''

    console.log (new Array 72).join '-'
    console.log 'Identified Functions'

    funcs = _.sortBy _.map(_.filter(@hooks, { type: 'FunctionHook' }), (func) -> {
      refactored: func.name + expand_known_params(func.params)
      original: if func.func == null then 'BROKEN' else func.func.id.name + expand_unknown_params(func.params)
    }), 'refactored'

    maxFuncLength = _.last(_.sortBy(_.map(funcs, (f) -> f.refactored.length))) + 1

    for ig, func of funcs
      console.log ' •', func.refactored, (new Array(Math.max(maxFuncLength - func.refactored.length, 0)).join ' '), '→', func.original
    console.log ''


module.exports = new HookCollection [], EVENTS
