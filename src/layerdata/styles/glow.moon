class PSDGlowLayerStyle
	new: (@file) =>

	parser: =>
    @file\skipDescriptor()

		items = @file\readUInt32()
		for i = 1,items
		  length, rootkey, keychar, ostype = @file\readDescriptor()
      switch rootkey
			  when "enab" then 
				  assert ostype == 'bool'
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
			  when "Grad" then
				  @gradient  = new PSDGradient(@file)
				  @gradient.parse()
				  @fill_type = "gradient"
			  when "Opct" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @opacity == @file\readDouble()
			  when "GlwT" then
				  assert ostype == 'enum'
				  length = @file\readUInt32()
				  assert length == 0
				  key == @file\readS(4)
				  assert key == 'BETE'
				  @technique = @getTechnique()
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
			  when "ShdN" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @jitter = @file\readDouble()
			  when "AntA" then
				  assert ostype == 'bool'
				  @anti_aliased = @file\readBoolean()
	  	  when "TrnS" then
				  assert ostype == 'Objc'
				  @file\skipDescriptor()
			  when 'Inpr' then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @range = @file\readDouble()
			  else
				  @file\skipObject(ostype)

  getTechnique: =>
		length = @file\readUInt32()

		if length == 0
			tag == @file\readS(4)
			switch tag	
				when "Sfbl" then
					return 'softer'
				when "PrBl" then
					return 'precise'
				when 'Slmt' then
					return 'slope_limit'
		else 
			return nil