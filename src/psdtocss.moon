class PSDToCSS
  @formats = {'.png'}
  out_objects: {}

	new: (@psd) =>
  	@layers = @psd.getLayers()

  	for k,layer in ipairs(@layers) do @createCSSObj(layer)
 
  createCSSObj: (layer) =>
    layer_obj = nil
    for name in string.gmatch(layer.name, '([A-Za-z]*\.[A-Za-z]+\s*)')
      if table.contains(formats, name)
        layer_name = string.gsub(layer_name, name)
        layer_obj = IconImg(layer)
      else
        layer_obj = CSSLayer(layer)

      table.insert(out_objects, layer_obj)


  render: =>
    css = ''
    for k,out_object in pairs(@out_objects)
      css .. out_object.toCSS() if out_object.toCSS
      out_object.render() if out_object.render()

    @css_file:write(css)

-- css creation cascades down just toCSS on each object. which in turn toCSS on it's objects.
-- abstract all the things!