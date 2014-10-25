if window?
  parser = require 'gom-html-parser'
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


# Helper for expecting errors to be thrown when parsing.

fails = (title, sources, message, pending) ->
  itFn = if pending then xit else it

  if !(sources instanceof Array)
    sources = [sources]

  sources.forEach (source, i) ->

    describe "#{title} - #{i + 1}", ->
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

        ],

        [
          {
            tag: 'div'
          }
        ]

    parse "style attribute", [

          "<div style='color:red; background-color:transparent'></div>"

          "< div  style=' color : red ; background-color : transparent ;' ></ div >"

          """
          <
          div
            style="
            color:red;
            background-color:transparent;
            "
          ></
          div
          >
          """

        ],

        [
          {
            tag: 'div'
            attributes:
              style:
                'color': 'red'
                'background-color': 'transparent'
          }
        ]

    parse "class attribute", [

          "<div class='foo bar pug'></div>"

          "< div  class='  foo   bar   pug  ' ></ div >"

          """
          <
          div
            class ="
              foo
              bar
              pug
            "
          ></
          div
          >
          """

        ],

        [
          {
            tag: 'div'
            attributes:
              class: ["foo", "bar", "pug"]
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

        ],

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

    parse "nested tags with text", [

          """Hello <a href="https://thegrid.io">world <span class="name big">I am here </span>!</a>..."""

          """
            Hello <a href="https://thegrid.io">world <span class="name big">I am here </span>!</a>...
          """

          """
            <!-- <ignore> this! --> Hello <a href="https://thegrid.io">world <!-- <ignore> this! --><span class="name big"><!-- <ignore> this! -->I am here </span>!</a>...<!-- <ignore> this! -->
          """

        ],

        [
          "Hello "
          {
            tag: 'a'
            attributes:
              href: "https://thegrid.io"
            children: [
              "world "
              {
                tag: 'span'
                attributes:
                  class: ['name','big']
                children: [
                  "I am here "
                ]
              }
              "!"
            ]
          }
          "..."
        ]

    parse "html doc", [

          """
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8"/> <!-- self closing tag -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
              </head>
              <body>
                <h1>Hello World</h1>
              </body>
            </html>
          """,

          """
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="utf-8"> <!-- HTML5 empty tag -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
              </head>
              <body>
                <h1>Hello World</h1>
              </body>
            </html>
          """,

          """
            <!-- ignore -->
            <!DOCTYPE html>
            <!-- ignore -->
            <html>
              <!-- ignore -->
              <head>
                <!-- ignore -->
                <meta charset="utf-8"/>
                <!-- ignore -->
                <title>Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript</title>
                <!-- ignore -->
              </head>
              <!-- ignore -->
              <body>
                <!-- ignore -->
                <h1>Hello World</h1>
                <!-- ignore -->
              </body>
              <!-- ignore -->
            </html>
            <!-- ignore -->
          """

        ],

        [
          "<!DOCTYPE html>"
          {
            tag: 'html'
            children: [
              {
                tag: 'head'
                children: [
                  {
                    tag: 'meta'
                    attributes:
                      charset: "utf-8"
                  }
                  {
                    tag: 'title'
                    children: [
                      "Online version &raquo; PEG.js &ndash; Parser Generator for JavaScript"
                    ]
                  }
                ]
              }
              {
                tag: 'body'
                children: [
                  {
                    tag: 'h1'
                    children: [
                      "Hello World"
                    ]
                  }
                ]
              }
            ]
          }
        ]

    parse "all together", [
        """
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8"> <!-- HTML5 empty tag -->
          </head>
          <body>
            <section contenteditable>
              <div style='color:black; background-color:transparent'>
                Hello <a href="https://thegrid.io">world <span class="name big">I am here </span>!</a>
              </div>
            </section>
          </body>
        </html>
        """
      ],
      [
        "<!DOCTYPE html>"
        {
          tag: 'html'
          children: [
            {
              tag: 'head'
              children: [
                {
                  tag: 'meta'
                  attributes:
                    charset: "utf-8"
                }
              ]
            }
            {
              tag: 'body'
              children: [
                {
                  tag: 'section'
                  attributes:
                    contenteditable: true
                  children: [
                    {
                      tag: 'div'
                      attributes:
                        style:
                          'color': 'black'
                          'background-color': 'transparent'
                      children: [
                        "Hello "
                        {
                          tag: 'a'
                          attributes:
                            href: "https://thegrid.io"
                          children: [
                            "world "
                            {
                              tag: 'span'
                              attributes:
                                class: ['name','big']
                              children: [
                                "I am here "
                              ]
                            }
                            "!"
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]


  # Errors
  # ====================================================================

  describe "Helpful Errors", ->

    fails "Invalid Empty Tag",
      [
        """
        <div>
        """,
        """
        <section>
          <div>
            <div></div>
          </div>
        """
      ],
      "Invalid Empty Tag"

    fails "Mismatched Open & Close Tags",
      [
        """
        <div></section>
        """,
        """
        <section>
          <div>
            <div>
          </div>
        </section>
        """,
      ],

      "Mismatched Open & Close Tags"





