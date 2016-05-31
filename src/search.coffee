cheerio       = require 'cheerio'
request       = require 'request'
url           = require 'url'

defs    = require './defs'
{clean_string} = require './utils'

class Search
  constructor: (@options = {}) ->
    do @handleOptions

  handleOptions: =>
    @options.protocol     ?= 'http'             #
    @options.hostname     ?= 'www.leboncoin.fr' #
    @options.category     ?= 'annonces'         #
    @options.debug      ?= false                #
    @options.verbose    ?= false                #
    @options.page       ?= 1                    #
    @options.shouldbe     ?= ''                 #
    @options.query      ?= null                 #
    @options.region     ?= 'ile_de_france'      #
    @options.department   ?= null               #
    @options.urgency_only   ?= false            #
    @options.sort_by_price  ?= false            #
    @options.hide_photos  ?= false              #
    @options.in_title     ?= false              # search only in title
    @options.url      ?= false                  # force
    @options.location     ?= null
    @options.category_attrs ?= {}

  getUrl: =>
    return @options.url if @options.url
    pathname = "#{@options.category}/offres/#{@options.region}/"
    pathname += "#{@options.department}/" if @options.department?
    query  = {}
    query.o = parseInt(@options.page, 10) if @options.page > 1
    query.q = @options.query if @options.query
    query.f = @options.filter if @options.filter in ['c', 'p']
    query.ur = 1 if @options.urgency_only
    query.sp = 1 if @options.sort_by_price
    query.th = 0 if @options.hide_photos
    query.it = 1 if @options.in_title
    query.location = @options.location if @options.location

    for k, v of @options.category_attrs
      query[k] = v

    return url.format
      hostname: @options.hostname
      protocol: @options.protocol
      pathname: pathname
      query:  query

  parseHTML: (html) =>
    results = []
    opts =
      normalizeWhitespace: true
      decodeEntities: true
    $ = cheerio.load html, opts
    for entry in $('#listingAds > .list.mainList > .tabsContent > ul > li > a')

      results.push
        href:  'https:' + entry.attribs.href
        title: entry.attribs.title
        date:  clean_string $(entry).find('.item_infos > aside > p').html()
        location: clean_string $(entry).find('.item_infos > p:nth-child(3)').html()
        price: clean_string $(entry).find('.item_price').html()
        image: $(entry).find('.lazyload').attr('data-imgsrc')
    return results

  perform: (callback) =>
    _url = do @getUrl
    request _url, (error, response, html) =>
      results = @parseHTML html
      callback
        error:  error
        response: response
        html:   html
        results:  results

module.exports = Search
