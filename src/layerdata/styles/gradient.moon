class PSDGradientLayerStyle
	new: (@file) => 
  
  parser: =>
    @file\skipDescriptor()

		items = @file\readUInt32()
		for i = 1,items
		  length, rootkey, keychar, ostype = @file\readDescriptor()
      switch rootkey
			  when "enab" then 
				  @enabled = @file\readBoolean()
			  when "Md  " then 
			  	assert ostype == 'enum'
				  length = @file\readUInt32()
				  key    = @file\readS()
				  assert key == 'BlnM'
				  @blend_mode = @file\readBlendmode()		 
			  when "Clr " then
				  assert ostype == 'Objc'
				  @color = @native_color = @file\readRGBColorspace()
			  when "Opct" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @opacity == @file\readDouble()
			  when "Grad" then
				  assert ostype == 'Objc'
				  @gradient = new PSDGradient(@file)
				  @gradient.parse()
			  when "Angl" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Ang'
				  @angle = @file\readDouble()
			  when "Type" then
				  assert ostype == 'enum'
				  length = @file\readUInt32()
				  assert length == 0			
				  key = @file\readS(4)
				  assert key == 'GrdT'	  
				  @style = @getGradientStyle()
			  when "Rvrs" then
				  assert ostype == 'bool'
				  @reverse = @file\readBoolean()
			  when "Algn" then
				  assert ostype == 'bool'
				  @align_with_layer = @file\readBoolean()
			  when "Scl" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @scale = @file\readDouble()
			  when "Ofst" then
				  assert ostype == 'Objc'
				  horizontal_offset, vertical_offset = @file\readObjectPoint()
			  else
				  @file\skipObject(ostype)

  getGradientStyle: =>
	  tag = @file\readS(4)
	  style = ""

	  switch tag
		  when "Lnr" then
			  style = "linear"
		  when "Rdl" then
			  style = "radial"
		  when "Angl" then
			  style = "angle"
		  when "Rflc" then
			  style = "reflected"
		  when "Dmnd"
			  style = "diamond"

	  return style