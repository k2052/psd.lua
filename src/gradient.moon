class PSDGradient
  color_stops: {}
  transparency_stops: {}

  new: (@file) =>
    @file\skipDescriptorHead()

    items = @file\readUInt32()
    for i = 1,items
      length, rootkey, keychar, ostype = @file\readDescriptorHead()

      switch rootkey
        when 'Nm  ' then
          assert ostype == 'TEXT'
          @name = @file\readCstring()
        when 'GrdF' then
          assert ostype == 'enum'
          @file\readDescriptorKey('GrdF')
          @file\readDescriptorKey('CstS')
        when "Intr" then
          assert ostype == 'doub'
          @smoothness = @file\readDouble()
        when "Clrs" then
          assert ostype == 'Vlls'
          @color_stops_count = @file\readUInt32()

          for i = 1,color_stops_count
            color_stop = {}
            @checkColorStopDescriptor()

            color_stop.actual_color = @file\readRGBColorspace()
            @file\readDescriptorKey('Type')

            ostype = @file\readS(4)
            assert ostype == 'enum'

            @file\readDescriptorKey()

            key = @file\readDescriptorKey()
            switch key
              when "FrgC" then
                color_stop.color_type = "foreground"
              when "BckC" then
                color_stop.color_type = "background"
              when "UsrS" then
                color_stop.color_type = "user"
            
            @file\readDescriptorKey('Lctn')

            ostype = @file\readS(4)
            assert ostype == 'long'

            color_stop.location = @file\readUInt32()

            @file\readDescriptorKey('Mdpn')

            ostype = @file\readS(4)
            assert ostype == 'long'
            color_stop.midpoint = @file\readInt()
        when "Trns" then
          assert ostype == 'Vlls'
          transparency_stops_count = @file\readUInt32()
          
          for i = 1,transparency_stops_count
            transparency_stop = {}
            
            @checkTransparencyStopDescriptor() 

            transparency_stop.opacity = @file\readDouble()

            @file\readDescriptorKey('Lctn')

            ostype = @file\readS(4)
            assert ostype == 'long'
            transparency_stop.location = @file\readUInt32()
 
            @file\readDescriptorKey('Mdpn')
            ostype = @file\readS(4)
            assert ostype == 'long'
            transparency_stop.midpoint = @file\readUInt32()
        else
          @file\skipObject(ostype)
   
  checkColorStopDescriptor: =>
    ostype = @file\readS(4)
    assert ostype == 'Objc'

    length = @file\readUInt32() * 2
    @file\skip(length)

    @file\readDescriptorKey('Clrt')

    items = @file\readInt()
    assert items == 4
    
    @file\readDescriptorKey('Clr ')

    ostype = @file\readS(4)
    assert ostype == 'Objc'   
  
  checkTransparencyStopDescriptor: =>
    ostype = @file\readS(4)
    assert ostype == 'Objc'

    length = @file\readUInt32() * 2
    @file\skip(length)

    @file\readDescriptorKey('Trns')

    items = @file\readInt()
    assert items == 3

    @file\readDescriptorKey('Opct')

    ostype = @file\readS(4)
    assert ostype == 'UntF'

    key = @file\readS(4)
    assert key == '#Prc'

  mergeStops: =>

  -- This is only a css fragment with the color-stops 
  -- e.g rgba(30,87,153,1) 0%,rgba(41,137,216,1) 50%,
  -- the layer style will spit out the full css style/background image
  toCSS: =>
    @mergeStops()

    result = ''
    for key,value in ipairs(@merged) 
      result .. string.format("rgba(%,%,%,%), %,", v.color.red, v.color.green, v.color.blue, opacity * 0.01, position..'%')

    return result