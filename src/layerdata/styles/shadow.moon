class PSDShadowLayerStyle
	enabled: false
	opacity: 1.0

  new: (@file, @inner = false) => 
  
  parse: =>
    @file\skipDescriptor()

		items = @file\readUInt32()
		for i = 1,items
			length, rootkey, keychar, ostype = @file\readDescriptor()

      switch rootkey
			  when 0 then	
				  if keychar == 'layerConceals'
					  @knocks_out = @file\readBoolean()
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
			  when "uglg" then
				  assert ostype == 'bool'
				  @use_global_light = @file\readBoolean() 
			  when 'lagl' then 
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Ang'
				  @angle = @file\readDouble()
			  when "Dstn" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Pxl'
				  @distance = @file\readDouble()
			  when "Ckmt" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Pxl'
				  @spread = @file\readDouble()
			  when "blur" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Pxl'
				  @size = @file\readDouble()
			  when "Nose" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @noise = @file\readDouble()
			  when "AntA" then
				  assert ostype == 'bool'
				  @anti_aliased = @file\readBoolean()
			  when "TrnS" then
				  assert ostype == 'Objc'
				  @file\skipDescriptor()
			  else
				  @file\skipObject(ostype)