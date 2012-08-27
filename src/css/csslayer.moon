class CSSLayer
  css: ''

  new: (@layer) =>

  toCSS: =>
    for k,style in ipairs(@layer.styles)
      if style.toCSS
        @css .. style.toCSS()

    return @css