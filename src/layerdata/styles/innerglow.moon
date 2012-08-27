class PSDInnerGlowLayerStyle extends PSDGlowLayerStyle
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
			  when 'glwS' then
				  assert ostype == 'enum'
				  length = @file\readUInt32()
				  assert length == 0

				  key = @file\readS(4)
				  assert key == 'IGSr'

				  length = @file\readInt()
          if length == 0
            key == @file\readInt()
          else
            key = 0 
            @file\skip(length)

          switch key
	          when 'SrcC' then
		          @source = 'center' 
	          when 'SrcE' then
		          @source = 'edge'
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