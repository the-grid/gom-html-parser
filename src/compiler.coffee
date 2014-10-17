if window?
  parser      = require './parser'
else
  parser      = require '../lib/parser'

ErrorReporter = require 'error-reporter'

parse = (source) ->
  results = null

  try
    results = parser.parse source
  catch error
    errorReporter = new ErrorReporter source
    {message, line:lineNumber, column:columnNumber} = error
    errorReporter.reportError message, lineNumber, columnNumber

  return results

module.exports =

  # Parse CCSS to produce an AST.
  #
  # @param source [String] A CCSS expression.
  # @return [Array] The AST which represents `source`.
  #
  parse: parse