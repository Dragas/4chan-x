Sauce =
  init: ->
    return unless g.VIEW in ['index', 'thread'] and Conf['Sauce']

    links = []
    for link in Conf['sauces'].split '\n'
      try
        links.push link.trim() if link[0] isnt '#'
      catch err
        # Don't add random text plz.
    return unless links.length

    @links = links
    @link  = $.el 'a',
      target:    '_blank'
      className: 'sauce'
    Post.callbacks.push
      name: 'Sauce'
      cb:   @node

  sandbox: (url) ->
    E.url <%= importHTML('Images/Sandbox') %>

  rmOrigin: (e) ->
    return if e.shiftKey or e.altKey or e.ctrlKey or e.metaKey or e.button isnt 0
    # Work around mixed content restrictions (data: URIs have inherited origin).
    $.open @href
    e.preventDefault()

  createSauceLink: (link, post) ->
    return null unless link = link.trim()

    parts = {}
    for part, i in link.split /;(?=(?:text|boards|types|sandbox):?)/
      if i is 0
        parts['url'] = part
      else
        m = part.match /^(\w*):?(.*)$/
        parts[m[1]] = m[2]
    parts['text'] or= parts['url'].match(/(\w+)\.\w+\//)?[1] or '?'
    ext = post.file.url.match(/[^.]*$/)[0]

    skip = false
    for key of parts
      parts[key] = parts[key].replace /%(T?URL|IMG|[sh]?MD5|board|name|%|semi)/g, (_, parameter) ->
        type = Sauce.formatters[parameter] post, ext
        if not type?
          skip = true
          return ''

        if key is 'url' and parameter not in ['%', 'semi']
          type = JSON.stringify type if /^javascript:/i.test parts['url']
          type = encodeURIComponent type
        type

    return null if skip
    return null unless !parts['boards'] or post.board.ID in parts['boards'].split ','
    return null unless !parts['types']  or ext           in parts['types'].split  ','

    url = parts['url']
    url = Sauce.sandbox url if parts['sandbox']?

    a = Sauce.link.cloneNode true
    a.href = url
    a.textContent = parts['text']
    a.removeAttribute 'target' if /^javascript:/i.test parts['url']
    $.on a, 'click', Sauce.rmOrigin if parts['sandbox']?
    a

  node: ->
    return if @isClone or !@file

    nodes = []
    for link in Sauce.links when node = Sauce.createSauceLink link, @
      # \u00A0 is nbsp
      nodes.push $.tn('\u00A0'), node
    $.add @file.text, nodes

  formatters:
    TURL:  (post) -> post.file.thumbURL
    URL:   (post) -> post.file.url
    IMG:   (post, ext) -> if ext in ['gif', 'jpg', 'png'] then post.file.url else post.file.thumbURL
    MD5:   (post) -> post.file.MD5
    sMD5:  (post) -> post.file.MD5?.replace /[+/=]/g, (c) -> {'+': '-', '/': '_', '=': ''}[c]
    hMD5:  (post) -> if post.file.MD5 then ("0#{c.charCodeAt(0).toString(16)}"[-2..] for c in atob post.file.MD5).join('')
    board: (post) -> post.board.ID
    name:  (post) -> post.file.name
    '%':   -> '%'
    semi:  -> ';'
