gom-html-parser
=============

Parsers HTML to [GOM](https://github.com/the-grid/gom) flavored JSON. A [PEG.js](http://pegjs.majda.cz/) parser.

Input:

```html
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
```

Output:

```json
[
   "<!DOCTYPE html>",
   {
      "tag": "html",
      "children": [
         {
            "tag": "head",
            "children": [
               {
                  "tag": "meta",
                  "attributes": {
                     "charset": "utf-8"
                  }
               }
            ]
         },
         {
            "tag": "body",
            "children": [
               {
                  "tag": "section",
                  "attributes": {
                     "contenteditable": true
                  },
                  "children": [
                     {
                        "tag": "div",
                        "attributes": {
                           "style": {
                              "color": "black",
                              "background-color": "transparent"
                           }
                        },
                        "children": [
                           "Hello ",
                           {
                              "tag": "a",
                              "attributes": {
                                 "href": "https://thegrid.io"
                              },
                              "children": [
                                 "world ",
                                 {
                                    "tag": "span",
                                    "attributes": {
                                       "class": [
                                          "name",
                                          "big"
                                       ]
                                    },
                                    "children": [
                                       "I am here "
                                    ]
                                 },
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
```


## Features

- Style attribute parsed to object
- Class attribute parsed to array of classNames
- Supports HTML5 empty tags
- Helpful errors

For more, see the spec.

## Build & Test

`npm install`
`grunt test`

