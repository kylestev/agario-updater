fs = require('fs')
_ = require('lodash')
esprima = require('esprima')
escodegen = require('escodegen')
Helper = require('./lib/identifiers/Helper')
config = require('./config.json')

analyze = (root, identifiers, tree) ->
  _.each identifiers, (identifier) ->
    # begin the visit
    identifier.beforeVisit()
    identifier.visit(root, tree)
    identifier.afterVisit()

analyzeRevision = (revision, filename) ->
  fs.readFile filename, { encoding: 'ASCII' }, (err, contents) ->
    if err
      throw err

    # parse the AST
    tree = esprima.parse contents, { comments: true }

    findJQueryOnLoad = (tree) ->
      _.find tree, (node) ->
        Helper.matchExpressionType node, 'CallExpression'

    deobbers = require('./lib/deobbers')
    _.each deobbers, (deobber) -> (new deobber).transform tree

    # go to the body of the jQuery onload function call
    jQueryOnLoadStmt = findJQueryOnLoad tree.body
    root = jQueryOnLoadStmt.expression.callee.body.body

    # load all the identifiers
    identifiers = require('./lib/identifiers')

    # boot each identifier.
    _.each identifiers, (identifier) -> identifier.boot()

    # analyze our loaded identifiers
    elapsed = Helper.stopWatch () ->
      analyze root, identifiers, tree

    console.log 'Analyzed Revision', revision, 'in', elapsed.toFixed(3) + 's'
    _.first(_.values identifiers).hooks.modScript()
    Helper.injectDefered(config)

    # generate the code
    codegenElapsed = Helper.stopWatch () ->
      fs.writeFile './generated.js', escodegen.generate(tree, { comment: true })

    console.log 'generating code took', codegenElapsed + 's'


analyzeRevisions = () ->
  revisionMatcher = /^([\d]{4}-[\d]{2}-[\d]{2})\.js$/i

  extractRevision = (file) ->
    match = revisionMatcher.exec file
    match and match[1]
  fs.readdir './revisions', (err, files) ->
    revisions = _.filter _.map(files, (file) ->
      revision = extractRevision file
      if not revision
        return
      return { name: revision, path: './revisions/' + revision + '.js' }
    ), (revision) -> revision != null

    _.each revisions, (revision) ->
      analyzeRevision revision.name, revision.path

# analyzeRevisions()
analyzeRevision 'current', './client.js'
# analyzeRevision 'refactored', './refactored.js'
