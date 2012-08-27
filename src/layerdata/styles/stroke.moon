class PSDStrokeLayerStyle extends PSDGradientLayerStyle
	new: (@file) =>

	parse: =>
    @file\skipDescriptor()

		items = @file\readUInt32()
		for i = 1,items
			length, rootkey, keychar, ostype = @file\readDescriptor()

      switch rootkey
			  when 0 then	
			    if keychar == "phase"
				    assert ostype == 'Objc'
				    pattern_horizontal_phase, pattern_vertical_phase = @file\readObjectPoint()
			    else
					  @file\skipObject(ostype)
		    when "enab"
			    assert ostype == 'bool'
			    @enabled = @file\readBoolean()
		    when "Styl" then
				  assert ostype == 'enum'
				  length = @file\readUInt32()
				  assert length == 0

				  key = @file\readS(4)
				  assert key == 'FStl'

				  length = @file\readInt()
          if length == 0
            key == @file\readInt()
          else
            key = 0 
            @file\skip(length)

			    switch key
				    when "OutF" then
					    @position = "outside"
				    when "InsF" then
					    @position = "inside"
				    when "CtrF" then
					    @position = "center"

		    when "PntT" then
				  length = @file\readUInt32()
				  assert length == 0

				  key = @file\readS(4)
				  assert key == 'FrFl'

				  length = @file\readInt()
          if length == 0
            key == @file\readInt()
          else
            key = 0 
            @file\skip(length)

	        switch key
		        when "SClr" then
			        @fill_type = "solid"
		        when "GrFl" then
			        @fill_type = "gradient"
		        when "Ptrn" then
			        @fill_type = "pattern"
			  when "Md  " then 
			  	assert ostype == 'enum'
				  length = @file\readUInt32()
				  key    = @file\readS(4)
				  assert key == 'BlnM'
				  @blend_mode = @file\readBlendmode()		 
			  when "Opct" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
				  @opacity == @file\readDouble() * 2.55 + 0.5
		    when "Sz  " then
			    assert ostype == 'Untf'
			    key = @file\readS(4)
			    assert key == '#Pxl'
			    @size = @file\readDouble()
			  when "Clr " then
				  assert ostype == 'Objc'
				  @color = @native_color = @file\readRGBColorspace()
			  when "Grad" then
				  assert ostype == 'Objc'
				  @gradient = new PSDGradient(@file)
				  @gradient.parse()
			  when "Angl" then
				  assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Ang'
				  @gradient_angle = @file\readDouble()
			  when "Type" then
				  assert ostype == 'enum'
				  length = @file\readUInt32()
				  assert length == 0			
				  key = @file\readS(4)
				  assert key == 'GrdT'	  
				  @gradient_style = @getGradientStyle()
			  when "Rvrs" then
				  assert ostype == 'bool'
				  @gradient_reverse = @file\readBoolean()
		    when "Scl " then
		    	assert ostype == 'Untf'
				  key = @file\readS(4)
				  assert key == '#Prc'
	  
			    if @fill_type = "gradient"
			  	  @gradient_scale = @file\readDouble()
			    else
			  	  @pattern_scale = @file\readDouble()
		    when "Algn" then
			    assert ostype == 'bool'
			    @gradient_align = @file\readBoolean()
			  when "Ofst" then
				  assert ostype == 'Objc'
				  horizontal_offset, vertical_offset = @file\readObjectPoint()
		    when "Ptrn" then
			    @pattern = @getPattern()
		    when "Lnkd" then
			    assert ostype == 'bool'
			    @pattern_link = @file\readBoolean()
			  else
				  @file\skipObject(ostype)
  
    if @gradient @setGradientDetails()

  getPattern: =>
    pattern = {
    	indentifier: {}
    }
    @file\skipDescriptor()

		items = @file\readUInt32()
		for i = 1,items
			length, rootkey, keychar, ostype = @file\readDescriptor()

      switch rootkey
	      when 'Nm  ' then
		      assert ostype == 'TEXT'
		      pattern\length = @file\readUInt32()
		      pattern\name   = @file\readS(pattern.length)
	      when "Idnt" then
		      assert ostype == 'TEXT'
		      indentifier_length = @file\readUInt32()

		      for	i = 1,indentifier_length
			      table.insert(pattern.indentifier, @file\readUInt16())
	      else
		      @file\skipObject(ostype)

    return pattern