class PSDInnerShadowLayerStyle extends PSDShadowLayerStyle
	new: (file, @inner = true) => 
		super(file)
  
	parse: =>
		super()