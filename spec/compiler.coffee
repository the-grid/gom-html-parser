if window?
  parser = require 'html2json'
else
  chai = require 'chai' unless chai
  parser = require '../lib/compiler'

{expect, assert} = chai


parse = (title, sources, expectation, pending) ->
  itFn = if pending then xit else it

  if !(sources instanceof Array)
    sources = [sources]

  num = sources.length

  sources.forEach (source, i) ->

    describe "#{title} - #{i + 1}", ->
      result = null

      itFn 'ok ✓', ->
        result = parser.parse source
        expect(result).to.be.an 'array'

      if expectation
        itFn 'commands ✓', ->
          expect(result).to.eql expectation


equivalent = () -> # ( "title", source0, source1, source2...)
  sources = [arguments...]
  title = sources.splice(0,1)[0]
  results = []
  describe title + " ok", ->
    it "sources ok ✓", ->
      for source, i in sources
        results.push parser.parse source
        assert results[results.length-1].commands?, "source #{i} is ok"
  describe title, ->
    for source, i in sources
      if i isnt 0
        it "source #{i} == source #{i - 1}  ✓", ->
          expect(results[1]).to.eql results.splice(0,1)[0]


# Helper function for expecting errors to be thrown when parsing.
#
# @param source [String] CCSS statements.
# @param message [String] This should be provided when a rule exists to catch
# invalid syntax, and omitted when an error is expected to be thrown by the PEG
# parser.
# @param pending [Boolean] Whether the spec should be treated as pending.
#
expectError = (source, message, pending) ->
  itFn = if pending then xit else it

  describe source, ->
    predicate = 'should throw an error'
    predicate = "#{predicate} with message: #{message}" if message?

    itFn predicate, ->
      exercise = -> parser.parse source
      expect(exercise).to.throw Error, message


describe 'HTML-to-JSON', ->

  it 'should provide a parse method', ->
    expect(parser.parse).to.be.a 'function'


  # Basics
  # ====================================================================

  describe "Basics", ->

    parse "lonely tag", [

          "<div></div>"

          "< div ></ div >"

          """
          <
          div
          ></
          div
          >
          """

        ]

        [
          {
            tag: 'div'
          }
        ]

    parse "nested tags", [

          "<section><div><div></div></div></section>"

          """
          <section>
            <div>
              <div></div>
            </div>
          </section>
          """

        ]

        [
          {
            tag: 'section'
            children: [
              {
                tag: 'div'
                children: [
                  {
                    tag: 'div'
                  }
                ]
              }
            ]
          }
        ]

