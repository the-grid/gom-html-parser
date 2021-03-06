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

    parse "script tag w/ CDATA", [
        """<script type="text/javascript">/* <![CDATA[ */

        var jsexec = dj.util.JSExec(dj.context.jsexec);
        try { console.group("DJ JSExec:"); console.info("[ begin jsexec ]"); }
        catch (e) { var _fnc = function(){}; console = {log: _fnc, info: _fnc, error: _fnc, dir: _fnc, group: _fnc, groupEnd: _fnc}; }
        //------------------------------
        jsexec(0,"dj.module.header2012.userDetails.showUserName",function(){dj.module.header2012.userDetails.showUserName = function(){       dojo.removeClass(dojo.query(".uNav")[0], "hidden");       dj.util.User.renderFirstName("userName");       var uNamePlaceholder = dojo.byId("userName").innerHTML;       if (uNamePlaceholder && uNamePlaceholder!=='' && uNamePlaceholder!=='undefined') {         uNamePlaceholder += "'s Journal";               } else {         dj.util.User.renderCallsign("userName");         var uNamePlaceholder = dojo.byId("userName").innerHTML;         uNamePlaceholder += "'s Journal";               }       dojo.byId("userName").innerHTML = uNamePlaceholder;       dojo.place("<span class='sym'></span>", dojo.byId("userName"),"last"); }});
        jsexec(1,"dojo.removeClass",function(){dojo.removeClass(dojo.query(".custNav")[0], "hidden");});
        jsexec(2,"dj.module.header2012.editionSwitcher.init",function(){dj.module.header2012.editionSwitcher.init();});
        jsexec(3,"dj.util.Tealium.init",function(){dj.util.Tealium.init();dj.util.Omniture.init();dj.util.Tracking.omniture.init();var pDatePlaceholder = dojo.byId('pageDatePlaceholder'); var s = "";var i = pDateinGMT.indexOf(",");var gmtDate = new Date(pDateinGMT.substring(0, i + 1) + " " + pDateinGMT.substring(i + 1));if(typeof gmtDate !== 'undefined') {  s = dj.util.Date.simpleDateFormat.format(gmtDate,"EE, MMM d, yyyy") + " As of " + dj.util.Date.simpleDateFormat.format(gmtDate,"h:mm a");} else if(pDate && pDate !== 'undefined') {  s = pDate;}if(pDatePlaceholder && pID !== '0_0_WCR_0001' && s !== "") { pDatePlaceholder.innerHTML = s; };(function(){var edition=dj.util.Cookie.getCookie('wsjregion'); if(edition =='asia'){dj.context.videoCenter.host='video.asia.wsj.com';} else if(edition=='europe'){dj.context.videoCenter.host='video.europe.wsj.com'}})();dj.util.Cookie.deleteGroupCookie("DJCOOKIE", "weatherJson");});
        jsexec(4,"dojo.query",function(){dojo.query(".meta_date")[0].innerHTML = pDate;});
        jsexec(5,"if",function(){if(window.location.pathname==="/public/page/factiva.html"){dojo.removeClass(dojo.byId("factivaCustomerService"),"hidden");}});
        jsexec(6,"nielsenTracking.init",function(){nielsenTracking.init();});
        jsexec(7,"dj.context.videoCenter.height",function(){dj.context.videoCenter.height=840; dj.context.videoCenter.width=418; dj.context.videoCenter.popUpPageURL = 'http://live.wsj.com/public/page/video-popup.html'; dj.util.VideoUtils.popUpPlayer = function(parameters) {      var popUpPageURL = "/public/page/0_0_WP_3001.html";      if(dj.context.videoCenter.popUpPageURL) {        popUpPageURL =dj.context.videoCenter.popUpPageURL;      }      if (dj.context.videoCenter.height){        var popUpWindow = window.open(popUpPageURL + '?currentPlayingLocation=' + parameters.playLocation + '&currentlyPlayingCollection=' + escape(parameters.collection) + '&currentlyPlayingVideoId=' + parameters.videoID, 'popUpPlayer', 'height='+dj.context.videoCenter.height+',width='+dj.context.videoCenter.width+',left=' + ((screen.width - Number(parameters.width)) / 2) + ',top=' + (screen.height - Number(parameters.height)) / 2 + ',resizable=no,scrollbars=no,toolbar=no,status=no');      }      else{        var popUpWindow = window.open(popUpPageURL + '?currentPlayingLocation=' + parameters.playLocation + '&currentlyPlayingCollection=' + escape(parameters.collection) + '&currentlyPlayingVideoId=' + parameters.videoID, 'popUpPlayer', 'height=690,width=510,left=' + ((screen.width - Number(parameters.width)) / 2) + ',top=' + (screen.height - Number(parameters.height)) / 2 + ',resizable=yes,scrollbars=no,toolbar=no,status=no');      }    };});
        jsexec(8,"setMetaData",function(){setMetaData('subsection','DJ Newswires');setMetaData('csource','DJ Newswires');setMetaData('ctype','article');setMetaData('pagename','T   Wire_BT-CO-20130718-711176');setMetaData('abasedocid','BT-CO-20130718-711176');setMetaData('apublished','2013-07-18T15:14:00');setMetaData('section','Article');setMetaData('apage','T   Wire');setMetaData('primaryproduct','Online Journal');setMetaData('atype','T   Wire');setMetaData('sitedomain','online.wsj.com');setMetaData('caccess','free');setMetaData('basesection','WSJ_TWire');setMetaData('aheadline','Panasonic, Sanyo to Pay $56.5 Million for Price Fixing - DOJ');setMetaData('displayname','Newswires Article Layout');});
        jsexec(9,"dj.module.facebook.connect.init",function(){dj.module.facebook.connect.init();});
        jsexec(10,"try",function(){try{dojo.connect(dojo.byId("forceMobile"),"onclick",function(){dj.util.Cookie.setGroupCookie("DJSESSION","mcookie","force-mobile");});}catch(err){console.log("Error: Not setting mobile cookie.")};});
        jsexec(11,"dj.util.Tracking.omniture.firePixel",function(){dj.util.Tracking.omniture.firePixel();});
        jsexec(12,"dojo.getObject",function(){dojo.getObject("dj.context.autocomplete",true).exclusionlist="XBUE,XBAH,XCNQ,XTNX,XCYS,XCAI,XSTU,XBER,XHAN,XTAE,XAMM,XKAZ,XKUW,XCAS,XMUS,XKAR,XLIM,DSMD,XMIC,RTSX,XSAU,XBRA,XCOL,XADS,XDFM,XCAR,MISX"});
        jsexec(13,"dj.module.header2012.localWeather.init",function(){dj.module.header2012.localWeather.init();});
        jsexec(14,"setTimeout",function(){setTimeout("if(dj.util.Cookie.getCookie('djmcn')==='true'){if(dojo.byId('hat_tab_secure')){dojo.removeClass(dojo.byId('hat_tab_secure'),'hidden');}if(dojo.byId('hat_tab_chat')){dojo.removeClass(dojo.byId('hat_tab_chat'),'hidden');}}",2000);});
        jsexec(15,"dojo.getObject",function(){dojo.getObject("dj.context.autocomplete",true).exclusionlist="XBUE,XBAH,XCNQ,XTNX,XCYS,XCAI,XSTU,XBER,XHAN,XTAE,XAMM,XKAZ,XKUW,XCAS,XMUS,XKAR,XLIM,DSMD,XMIC,RTSX,XSAU,XBRA,XCOL,XADS,XDFM,XCAR,MISX"});
        jsexec(16,"dj.module.header2012.lifp.init",function(){dj.module.header2012.lifp.init();});
        jsexec(17,"dj.module.header2012.sectionMenu.init",function(){dj.module.header2012.sectionMenu.init();});
        jsexec(18,"if",function(){if(window.location.pathname==="/public/page/rc-login.html" || window.location.pathname==="/public/page/rc-login2.html"){dj.widget.networkHat.RCLogin.init();} });
        jsexec(19,"if",function(){if(dj.module.mst){dj.module.mst.preview.decorator.init();}});
        jsexec(20,"dj.module.entitlements.googleClickTrack.init",function(){dj.module.entitlements.googleClickTrack.init({expirationInterval: "1d+"});});
        jsexec(21,"dj.module.articleTextTab",function(){dj.module.articleTextTab=new dj.widget.article.text.ArticleTabText(dj.module.articleTabs.panels);});
        jsexec(22,"dj.module.articleTools.Initilizer",function(){new dj.module.articleTools.Initilizer('abtt',true,true);});
        jsexec(23,"dj.module.articleTools.Initilizer",function(){new dj.module.articleTools.Initilizer('abt',false,false,true);});
        jsexec(24,"dojo.query",function(){dojo.query('div[data-cb-ad-id]').forEach(function(tag,i){if(tag.id.match(/^ad0_0.*[GA][\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adTop")} else if(tag.id.match(/^ad0_0.*[C][\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adCirc")} else if(tag.id.match(/^ad0_0.*[B]$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adBH")} else if(tag.id.match(/^ad0_0.*[Z]$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adZ")} else if(tag.id.match(/^adEmailCircAd.*[\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adEM")};});});
        jsexec(25,"dj.context.hummingbird2Enabled",function(){dj.context.hummingbird2Enabled = (function(){ if (dj.module.hummingbird2) { return dj.lang.connect(window, "onload", dj.module.hummingbird2, "onPageLoad"); } }());});
        jsexec(26,"dj.module.geotargeting.germanyScrim.init",function(){dj.module.geotargeting.germanyScrim.init();});
        jsexec(27,"if",function(){if (dojo.getObject("dj.module.video.liveMicroPlayer", true).init) { dj.module.video.liveMicroPlayer.init(); }});
        jsexec(28,"var",function(){var moreNode = dojo.byId("MoreIndustries_Container");if (moreNode) { dj.module.moreIndustries = new dj.widget.panel.SelectDropdownPanel(moreNode);}});
        jsexec(29,"if",function(){if (dojo.getObject("dj.module.panels.liveSlideshow", true).init) { dj.module.panels.liveSlideshow.init(); }});
        jsexec(30,"dj.module.header2012.autocomplete.searchExec",function(){dj.module.header2012.autocomplete.searchExec();});
        jsexec(31,"if",function(){if (dojo.getObject("dj.util.flash.template", true).scan) { dj.util.flash.template.scan(); } if (dojo.getObject("dj.util.onVisibleWidget", true).scan) {dj.util.onVisibleWidget.scan();} if (dojo.getObject("dj.util.onVisibleImg", true).scan) {dj.util.onVisibleImg.scan(); }});
        jsexec(32,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('headerPromoContainer','iframe' , {width: 377, height: 50,size:'377x50', site:'interactive.wsj.com', zone:'newswires',adClass:'M', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'true',classValue:'promo',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(33,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('ad0_0_WA_0006L','iframe' , {width: 728, height: 90,size:'728x90', site:'interactive.wsj.com', zone:'newswires',adClass:'G', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'true',classValue:'adSummary ad_728',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(34,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('editorsPicks_','iframe' , {width: 180, height: 150,size:'180x150', site:'interactive.wsj.com', zone:'newswires',adClass:'A', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'False',classValue:'adSummary',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(35,"dj.module.uberHat",function(){dj.module.uberHat = new dj.widget.uberHat.UberHat({"divExists":true}); dj.module.survey = new dj.widget.survey.SurveyPopup({"url":"http://survey.confirmit.com/wix/p913069351.aspx", "width":550, "height":525, "cookieName":"cambriaSurvey", "windowName":"cambriaSurvey", "userHasRole":"CAMBRIA", "enableInterval":"60s+", "noRepeatInterval":"90d+","frequencyPercent":100});dj.module.survey = new dj.widget.survey.SurveyPopup({"url":"http://survey.confirmit.com/wix1/p944166011.aspx", "width":550, "height":525, "cookieName":"hyattSurvey", "windowName":"hyattSurvey", "userHasRole":"HYATT", "enableInterval":"60s+", "noRepeatInterval":"90d+","frequencyPercent":100});});
        jsexec(36,"blueKai.blueKai.bk_track",function(){blueKai.blueKai.bk_track(true);});
        jsexec(37,"if",function(){if(dj.util.Cookie.getCookie("djmcn")==="true" && djcs.UserInfo.getGroup()==="DJN" && dojo.doc.URL.indexOf("#printMode")===-1){ dojo.create("script",{"src":"https://chat.wsj.com/chatMinimizedPopoutLink.js",type:"text/javascript"},dojo.query("body")[0]);}});
        jsexec(38,"dj.module.articleTextTab.playbookmark",function(){dj.module.articleTextTab.playbookmark();});
        jsexec(39,"var",function(){var beg=(new Date).getTime(),itv=setInterval(function(){dj.util.User.isLoggedIn(function(a){if(a){var b=dojo.query("a.md_index"),c,d;for(c=0,d=b.length;c<d;c++){if(b[c].href.indexOf("/index/SP%20500%20Futures")!==-1){b[c].href="/mdc/public/page/2_3028.html?category=Index&subcategory=U.S.&contract=SP%2520500%2520-%2520Mini%2520-%2520cme&catandsubcat=Index%257CU.S.&contractset=SP%2520500%2520Mini%2520-%2520cme";console.log(c);clearInterval(itv);break}}if((new Date).getTime()-beg>15e3){clearInterval(itv)}}else{clearInterval(itv)}})},1e3)});

        //------------------------------
        console.info("[ end jsexec ]");
        console.groupEnd();

        /* ]]> */</script>"""
      ],
      [
        {
          tag: 'script'
          attributes: {"type": "text/javascript"}
          children: [
            """/* <![CDATA[ */

        var jsexec = dj.util.JSExec(dj.context.jsexec);
        try { console.group("DJ JSExec:"); console.info("[ begin jsexec ]"); }
        catch (e) { var _fnc = function(){}; console = {log: _fnc, info: _fnc, error: _fnc, dir: _fnc, group: _fnc, groupEnd: _fnc}; }
        //------------------------------
        jsexec(0,"dj.module.header2012.userDetails.showUserName",function(){dj.module.header2012.userDetails.showUserName = function(){       dojo.removeClass(dojo.query(".uNav")[0], "hidden");       dj.util.User.renderFirstName("userName");       var uNamePlaceholder = dojo.byId("userName").innerHTML;       if (uNamePlaceholder && uNamePlaceholder!=='' && uNamePlaceholder!=='undefined') {         uNamePlaceholder += "'s Journal";               } else {         dj.util.User.renderCallsign("userName");         var uNamePlaceholder = dojo.byId("userName").innerHTML;         uNamePlaceholder += "'s Journal";               }       dojo.byId("userName").innerHTML = uNamePlaceholder;       dojo.place("<span class='sym'></span>", dojo.byId("userName"),"last"); }});
        jsexec(1,"dojo.removeClass",function(){dojo.removeClass(dojo.query(".custNav")[0], "hidden");});
        jsexec(2,"dj.module.header2012.editionSwitcher.init",function(){dj.module.header2012.editionSwitcher.init();});
        jsexec(3,"dj.util.Tealium.init",function(){dj.util.Tealium.init();dj.util.Omniture.init();dj.util.Tracking.omniture.init();var pDatePlaceholder = dojo.byId('pageDatePlaceholder'); var s = "";var i = pDateinGMT.indexOf(",");var gmtDate = new Date(pDateinGMT.substring(0, i + 1) + " " + pDateinGMT.substring(i + 1));if(typeof gmtDate !== 'undefined') {  s = dj.util.Date.simpleDateFormat.format(gmtDate,"EE, MMM d, yyyy") + " As of " + dj.util.Date.simpleDateFormat.format(gmtDate,"h:mm a");} else if(pDate && pDate !== 'undefined') {  s = pDate;}if(pDatePlaceholder && pID !== '0_0_WCR_0001' && s !== "") { pDatePlaceholder.innerHTML = s; };(function(){var edition=dj.util.Cookie.getCookie('wsjregion'); if(edition =='asia'){dj.context.videoCenter.host='video.asia.wsj.com';} else if(edition=='europe'){dj.context.videoCenter.host='video.europe.wsj.com'}})();dj.util.Cookie.deleteGroupCookie("DJCOOKIE", "weatherJson");});
        jsexec(4,"dojo.query",function(){dojo.query(".meta_date")[0].innerHTML = pDate;});
        jsexec(5,"if",function(){if(window.location.pathname==="/public/page/factiva.html"){dojo.removeClass(dojo.byId("factivaCustomerService"),"hidden");}});
        jsexec(6,"nielsenTracking.init",function(){nielsenTracking.init();});
        jsexec(7,"dj.context.videoCenter.height",function(){dj.context.videoCenter.height=840; dj.context.videoCenter.width=418; dj.context.videoCenter.popUpPageURL = 'http://live.wsj.com/public/page/video-popup.html'; dj.util.VideoUtils.popUpPlayer = function(parameters) {      var popUpPageURL = "/public/page/0_0_WP_3001.html";      if(dj.context.videoCenter.popUpPageURL) {        popUpPageURL =dj.context.videoCenter.popUpPageURL;      }      if (dj.context.videoCenter.height){        var popUpWindow = window.open(popUpPageURL + '?currentPlayingLocation=' + parameters.playLocation + '&currentlyPlayingCollection=' + escape(parameters.collection) + '&currentlyPlayingVideoId=' + parameters.videoID, 'popUpPlayer', 'height='+dj.context.videoCenter.height+',width='+dj.context.videoCenter.width+',left=' + ((screen.width - Number(parameters.width)) / 2) + ',top=' + (screen.height - Number(parameters.height)) / 2 + ',resizable=no,scrollbars=no,toolbar=no,status=no');      }      else{        var popUpWindow = window.open(popUpPageURL + '?currentPlayingLocation=' + parameters.playLocation + '&currentlyPlayingCollection=' + escape(parameters.collection) + '&currentlyPlayingVideoId=' + parameters.videoID, 'popUpPlayer', 'height=690,width=510,left=' + ((screen.width - Number(parameters.width)) / 2) + ',top=' + (screen.height - Number(parameters.height)) / 2 + ',resizable=yes,scrollbars=no,toolbar=no,status=no');      }    };});
        jsexec(8,"setMetaData",function(){setMetaData('subsection','DJ Newswires');setMetaData('csource','DJ Newswires');setMetaData('ctype','article');setMetaData('pagename','T   Wire_BT-CO-20130718-711176');setMetaData('abasedocid','BT-CO-20130718-711176');setMetaData('apublished','2013-07-18T15:14:00');setMetaData('section','Article');setMetaData('apage','T   Wire');setMetaData('primaryproduct','Online Journal');setMetaData('atype','T   Wire');setMetaData('sitedomain','online.wsj.com');setMetaData('caccess','free');setMetaData('basesection','WSJ_TWire');setMetaData('aheadline','Panasonic, Sanyo to Pay $56.5 Million for Price Fixing - DOJ');setMetaData('displayname','Newswires Article Layout');});
        jsexec(9,"dj.module.facebook.connect.init",function(){dj.module.facebook.connect.init();});
        jsexec(10,"try",function(){try{dojo.connect(dojo.byId("forceMobile"),"onclick",function(){dj.util.Cookie.setGroupCookie("DJSESSION","mcookie","force-mobile");});}catch(err){console.log("Error: Not setting mobile cookie.")};});
        jsexec(11,"dj.util.Tracking.omniture.firePixel",function(){dj.util.Tracking.omniture.firePixel();});
        jsexec(12,"dojo.getObject",function(){dojo.getObject("dj.context.autocomplete",true).exclusionlist="XBUE,XBAH,XCNQ,XTNX,XCYS,XCAI,XSTU,XBER,XHAN,XTAE,XAMM,XKAZ,XKUW,XCAS,XMUS,XKAR,XLIM,DSMD,XMIC,RTSX,XSAU,XBRA,XCOL,XADS,XDFM,XCAR,MISX"});
        jsexec(13,"dj.module.header2012.localWeather.init",function(){dj.module.header2012.localWeather.init();});
        jsexec(14,"setTimeout",function(){setTimeout("if(dj.util.Cookie.getCookie('djmcn')==='true'){if(dojo.byId('hat_tab_secure')){dojo.removeClass(dojo.byId('hat_tab_secure'),'hidden');}if(dojo.byId('hat_tab_chat')){dojo.removeClass(dojo.byId('hat_tab_chat'),'hidden');}}",2000);});
        jsexec(15,"dojo.getObject",function(){dojo.getObject("dj.context.autocomplete",true).exclusionlist="XBUE,XBAH,XCNQ,XTNX,XCYS,XCAI,XSTU,XBER,XHAN,XTAE,XAMM,XKAZ,XKUW,XCAS,XMUS,XKAR,XLIM,DSMD,XMIC,RTSX,XSAU,XBRA,XCOL,XADS,XDFM,XCAR,MISX"});
        jsexec(16,"dj.module.header2012.lifp.init",function(){dj.module.header2012.lifp.init();});
        jsexec(17,"dj.module.header2012.sectionMenu.init",function(){dj.module.header2012.sectionMenu.init();});
        jsexec(18,"if",function(){if(window.location.pathname==="/public/page/rc-login.html" || window.location.pathname==="/public/page/rc-login2.html"){dj.widget.networkHat.RCLogin.init();} });
        jsexec(19,"if",function(){if(dj.module.mst){dj.module.mst.preview.decorator.init();}});
        jsexec(20,"dj.module.entitlements.googleClickTrack.init",function(){dj.module.entitlements.googleClickTrack.init({expirationInterval: "1d+"});});
        jsexec(21,"dj.module.articleTextTab",function(){dj.module.articleTextTab=new dj.widget.article.text.ArticleTabText(dj.module.articleTabs.panels);});
        jsexec(22,"dj.module.articleTools.Initilizer",function(){new dj.module.articleTools.Initilizer('abtt',true,true);});
        jsexec(23,"dj.module.articleTools.Initilizer",function(){new dj.module.articleTools.Initilizer('abt',false,false,true);});
        jsexec(24,"dojo.query",function(){dojo.query('div[data-cb-ad-id]').forEach(function(tag,i){if(tag.id.match(/^ad0_0.*[GA][\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adTop")} else if(tag.id.match(/^ad0_0.*[C][\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adCirc")} else if(tag.id.match(/^ad0_0.*[B]$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adBH")} else if(tag.id.match(/^ad0_0.*[Z]$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adZ")} else if(tag.id.match(/^adEmailCircAd.*[\d]*$/) != null){ dojo.attr(tag.id, "data-cb-ad-id", "adEM")};});});
        jsexec(25,"dj.context.hummingbird2Enabled",function(){dj.context.hummingbird2Enabled = (function(){ if (dj.module.hummingbird2) { return dj.lang.connect(window, "onload", dj.module.hummingbird2, "onPageLoad"); } }());});
        jsexec(26,"dj.module.geotargeting.germanyScrim.init",function(){dj.module.geotargeting.germanyScrim.init();});
        jsexec(27,"if",function(){if (dojo.getObject("dj.module.video.liveMicroPlayer", true).init) { dj.module.video.liveMicroPlayer.init(); }});
        jsexec(28,"var",function(){var moreNode = dojo.byId("MoreIndustries_Container");if (moreNode) { dj.module.moreIndustries = new dj.widget.panel.SelectDropdownPanel(moreNode);}});
        jsexec(29,"if",function(){if (dojo.getObject("dj.module.panels.liveSlideshow", true).init) { dj.module.panels.liveSlideshow.init(); }});
        jsexec(30,"dj.module.header2012.autocomplete.searchExec",function(){dj.module.header2012.autocomplete.searchExec();});
        jsexec(31,"if",function(){if (dojo.getObject("dj.util.flash.template", true).scan) { dj.util.flash.template.scan(); } if (dojo.getObject("dj.util.onVisibleWidget", true).scan) {dj.util.onVisibleWidget.scan();} if (dojo.getObject("dj.util.onVisibleImg", true).scan) {dj.util.onVisibleImg.scan(); }});
        jsexec(32,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('headerPromoContainer','iframe' , {width: 377, height: 50,size:'377x50', site:'interactive.wsj.com', zone:'newswires',adClass:'M', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'true',classValue:'promo',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(33,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('ad0_0_WA_0006L','iframe' , {width: 728, height: 90,size:'728x90', site:'interactive.wsj.com', zone:'newswires',adClass:'G', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'true',classValue:'adSummary ad_728',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(34,"dj.widget.ad.AdManager.createAd",function(){dj.widget.ad.AdManager.createAd('editorsPicks_','iframe' , {width: 180, height: 150,size:'180x150', site:'interactive.wsj.com', zone:'newswires',adClass:'A', meta:'',metazone:'',category:'',frequency:'',cacheId:'',classEnabled:'False',classValue:'adSummary',styleValue:'',conditionType:'',conditionValue:'',conditionalString:''})});
        jsexec(35,"dj.module.uberHat",function(){dj.module.uberHat = new dj.widget.uberHat.UberHat({"divExists":true}); dj.module.survey = new dj.widget.survey.SurveyPopup({"url":"http://survey.confirmit.com/wix/p913069351.aspx", "width":550, "height":525, "cookieName":"cambriaSurvey", "windowName":"cambriaSurvey", "userHasRole":"CAMBRIA", "enableInterval":"60s+", "noRepeatInterval":"90d+","frequencyPercent":100});dj.module.survey = new dj.widget.survey.SurveyPopup({"url":"http://survey.confirmit.com/wix1/p944166011.aspx", "width":550, "height":525, "cookieName":"hyattSurvey", "windowName":"hyattSurvey", "userHasRole":"HYATT", "enableInterval":"60s+", "noRepeatInterval":"90d+","frequencyPercent":100});});
        jsexec(36,"blueKai.blueKai.bk_track",function(){blueKai.blueKai.bk_track(true);});
        jsexec(37,"if",function(){if(dj.util.Cookie.getCookie("djmcn")==="true" && djcs.UserInfo.getGroup()==="DJN" && dojo.doc.URL.indexOf("#printMode")===-1){ dojo.create("script",{"src":"https://chat.wsj.com/chatMinimizedPopoutLink.js",type:"text/javascript"},dojo.query("body")[0]);}});
        jsexec(38,"dj.module.articleTextTab.playbookmark",function(){dj.module.articleTextTab.playbookmark();});
        jsexec(39,"var",function(){var beg=(new Date).getTime(),itv=setInterval(function(){dj.util.User.isLoggedIn(function(a){if(a){var b=dojo.query("a.md_index"),c,d;for(c=0,d=b.length;c<d;c++){if(b[c].href.indexOf("/index/SP%20500%20Futures")!==-1){b[c].href="/mdc/public/page/2_3028.html?category=Index&subcategory=U.S.&contract=SP%2520500%2520-%2520Mini%2520-%2520cme&catandsubcat=Index%257CU.S.&contractset=SP%2520500%2520Mini%2520-%2520cme";console.log(c);clearInterval(itv);break}}if((new Date).getTime()-beg>15e3){clearInterval(itv)}}else{clearInterval(itv)}})},1e3)});

        //------------------------------
        console.info("[ end jsexec ]");
        console.groupEnd();

        /* ]]> */"""
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





