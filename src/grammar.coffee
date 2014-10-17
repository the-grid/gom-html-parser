# A CoffeeScript representation of the PEG grammar.
#
class Grammar

  ### Private ###


  # Create a string from a list of characters.
  # @private
  #
  # @param input [Array<String>, String] A list of characters, or a string.
  # @return [String] A string representation of the object passed to the
  # method.
  #
  @_toString: (input) ->
    return input if toString.call(input) is '[object String]'
    return input.join('') if toString.call(input) is '[object Array]'
    return ''


  # The type of error thrown by the PEG parser.
  # @note Assigned in constructor.
  # @private
  #
  # @param message [String] A description of the error.
  # @param expected [Array<Object>] A list of objects consisting of type,
  # value and description keys which represent valid statements.
  # @param found [String] The statement that found and caused the error.
  # @param offset [Number] The same as `column`, but zero-based.
  # @param line [Number] The line number where the error occurred.
  # @param column [Number] The column number where the error occurred.
  #
  _Error: null



  # Get the current column number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current column number.
  #
  _columnNumber: ->


  # Get the current line number as reported by the parser.
  # @note Assigned in constructor.
  # @private
  #
  # @return [Number] The current line number.
  #
  _lineNumber: ->



  # Construct a new Grammar.
  #
  # @param lineNumber [Function] A getter for the current line number.
  # @param columnNumber [Function] A getter for the current column number.
  # @param errorType [Function] A getter for the type of error thrown by the
  # PEG parser.
  #
  constructor: (parser, lineNumber, columnNumber, errorType) ->
    @parser = parser

    @_lineNumber = lineNumber
    @_columnNumber = columnNumber
    @_Error = errorType()


module.exports = Grammar
