class PSDImage
  @COMPRESSIONS = {
    0: 'Raw',
    1: 'RLE',
    2: 'ZIP',
    3: 'ZIPPrediction',
  }

  @channelsInfo = {
    {id: 0},
    {id: 1},
    {id: 2},
    {id: -1},
  }

  new: (@file, @header) =>
    @numPixels  = @getImageWidth() * @getImageHeight()
    @numPixels *= 2 if @getImageDepth() == 16

    @length = switch @getImageDepth()
      when 1 then 
        (@getImageWidth() + 7) / 8 * @getImageHeight()
      when 16 then 
        @getImageWidth() * @getImageHeight() * 2
      else 
        @getImageWidth() * @getImageHeight()

    @channelLength = @length
    @length        = @length * @getImageChannels()

    -- @channelData = Uint8Array(@length)
    @channelData = {}

    @startPos = @file\seek()
    @endPos   = @startPos + @length

    @pixelData = {}

  parse: =>
    @compression = @parseCompression()

    Log.debug "Image size: ".. @length .. @getImageWidth() .. "x" .. @getImageHeight()

    if table.contains({2, 3}, @compression)
      Log.debug "ZIP compression not implemented yet, skipping."
      return @file\skip(@endPos, false)

    @parseImageData()

  skip: =>
    Log.debug "Skipping image data"
    @file\skip(@length)

  parseCompression: => @file\readUInt16()

  parseImageData: =>
    Log.debug "Image compression: id=" .. @compression .. ", name=" .. PSDImage.COMPRESSIONS[@compression]

    switch @compression
      when 0 then 
        @parseRaw()
      when 1 then 
        @parseRLE()
      when 2 or 3 then 
        @parseZip()
      else
        Log.debug "Unknown image compression. Attempting to skip."
        return @file\skip(@endPos, false)

    @processImageData()

  parseRaw: (length = @length) =>
    Log.debug "Attempting to parse RAW encoded image..."

    @channelData = {}
    for i = 1,length
      table.insert(@channelData, @file\readUInt8())

    return true

  parseRLE: =>
    Log.debug "Attempting to parse RLE encoded image..."

    @byteCounts = @getByteCounts()

    Log.debug "Read byte counts. Current pos = ".. @file\seek() .. ", Pixels =" .. @length

    @parseChannelData()

  getImageHeight: => @header.rows
  getImageWidth: => @header.cols
  getImageChannels: => @header.channels
  getImageDepth: => @header.depth

  getByteCounts: =>
    byteCounts = {}
    for i = 1,@getImageChannels()
      for j = 0,@getImageHeight()
        table.insert(byteCounts, @file\readUInt32())

    byteCounts

  parseChannelData: =>
    chanPos   = 0
    lineIndex = 0

    for i = 1,@getImageChannels()
      Log.debug "Parsing channel #" .. i .. ", Start = " .. @file\seek()
      chanPos, lineIndex = @decodeRLEChannel(chanPos, lineIndex)

    return true

  decodeRLEChannel: (chanPos, lineIndex) =>
    for j = 0, @getImageHeight()
      byteCount = @byteCounts[lineIndex += 1]
      start     = @file\seek()

      while @file\seek() < start + byteCount
        len = @file\read(1)

        if len < 128
          len += 1
          data = @file\read len

          dataIndex = 0
          for k = chanPos,chanPos+len
            @channelData[k] = data[dataIndex += 1] 

          chanPos += len
        else if len > 128
          len = bit.bxor(len, 0xff)
          len += 2
          
          val   = @file\read(1)
          data  = {}
          for z in 0,len
           table.insert(data, val) 

          dataIndex = 0
          for k = chanPos,chanPos+len
            @channelData[k] = data[dataIndex += 1]

          chanPos += len

    chanPos, lineIndex

  processImageData: =>
    Log.debug "Processing parsed image data. " .. @channelData.length .. "pixels read."

    switch @header.mode
      when 1 
        @combineGreyscale8Channel() if @getImageDepth() is 8
        @combineGreyscale16Channel() if @getImageDepth() is 16
      when 3 
        @combineRGB8Channel() if @getImageDepth() is 8
        @combineRGB16Channel() if @getImageDepth() is 16
      when 4
        @combineCMYK8Channel() if @getImageDepth() is 8
        @combineCMYK16Channel() if @getImageDepth() is 16
      when 7
        @combineMultiChannel8()
      when 9
        @combineLAB8Channel() if @getImageDepth() is 8
        @combineLAB16Channel() if @getImageDepth() is 16

    @channelData = nil

  getAlphaValue: (alpha = 255) =>
    alpha = alpha * (@layer\blendMode\opacity / 255) if @layer
    return alpha

  combineGreyscale8Channel: =>
    if @getImageChannels() == 2
      for i = 1,@numPixels
        alpha = @channelData[i]
        grey  = @channelData[@channelLength + i]

        table.insertM(@pixelData, grey, grey, grey, @getAlphaValue(alpha))
    else
      for i = 1,@numPixels
        table.insertM(@pixelData, @channelData[i], @channelData[i], @channelData[i], @getAlphaValue())

  combineGreyscale16Channel: =>
    if @getImageChannels() is 2
      for i = 1,@numPixels,2
        alpha = Util.toUInt16 @channelData[i + 1], @channelData[i]
        grey  = Util.toUInt16 @channelData[@channelLength + i + 1], @channelData[@channelLength + i]

        table.insertM(@pixelData, grey, grey, grey,@getAlphaValue(alpha))
    else
      for i = 1,@numPixels,2
        pixel = Util.toUInt16 @channelData[i+1], @channelData[i]

        table.insertM(@pixelData, pixel, pixel, pixel, @getAlphaValue())

  combineRGB8Channel: =>
    for i = 1,@numPixels
      index = 0
      pixel = {red: 0, green: 0, blue: 0, alpha: 255}

      for chan in @channelsInfo
        switch chan.id
          when -1
            if @getImageChannels() is 4
              pixel\a = @channelData[i + (@channelLength * index)]
          when 0 then 
            pixel\r = @channelData[i + (@channelLength * index)]
          when 1 then 
            pixel\g = @channelData[i + (@channelLength * index)]
          when 2 then 
            pixel\b = @channelData[i + (@channelLength * index)]
        
        if chani.id is not -1 and @getImageChannels() is not 4
          index += 1

      table.insertM(@pixelData, pixel\r. pixel\g, pixel\b, @getAlphaValue(pixel.a))

  combineRGB16Channel: =>
    for i = 1,@numPixels,2
      index = 0
      pixel = {red: 0, green: 0, blue: 0, alpha: 255}

      for chan in @channelsInfo
        b1 = @channelData[i + (@channelLength * index) + 1]
        b2 = @channelData[i + (@channelLength * index)]

        switch chan.id
          when -1
            if @getImageChannels() is 4
              pixel.a = Util.toUInt16(b1, b2)
          when 0 then pixel.r = Util.toUInt16(b1, b2)
          when 1 then pixel.g = Util.toUInt16(b1, b2)
          when 2 then pixel.b = Util.toUInt16(b1, b2)
        
        if chan.id is not -1 and @getImageChannels() is not 4
          index += 1

      table.insertM(@pixelData, pixel.r, pixel.g, pixel.b, @getAlphaValue(pixel.a))

  combineCMYK8Channel: =>
    for i = 1,@numPixels
      if @getImageChannels() is 5
        a = @channelData[i]
        c = @channelData[i + @channelLength]
        m = @channelData[i + @channelLength * 2]
        y = @channelData[i + @channelLength * 3]
        k = @channelData[i + @channelLength * 4]
      else
        a = 255
        c = @channelData[i]
        m = @channelData[i + @channelLength]
        y = @channelData[i + @channelLength * 2]
        k = @channelData[i + @channelLength * 3]

      rgb = color.cmykToRGB(255 - c, 255 - m, 255 - y, 255 - k)

      table.insertM(@pixelData, rgb.r, rgb.g, rgb.b, @getAlphaValue(a))

  combineCMYK16Channel: =>
    for i = 1,@numPixels,2
      if @getImageChannels() is 5
        a = @channelData[i]
        c = @channelData[i + @channelLength]
        m = @channelData[i + @channelLength * 2]
        y = @channelData[i + @channelLength * 3]
        k = @channelData[i + @channelLength * 3]
      else
        a = 255
        c = @channelData[i]
        m = @channelData[i + @channelLength]
        y = @channelData[i + @channelLength * 2]
        k = @channelData[i + @channelLength * 3]

      rgb = color.cmykToRGB(255 - c, 255 - m, 255 - y, 255 - k)

      table.insertM(@pixelData, rgb.r, rgb.g, rgb.b, @getAlphaValue(a))

  combineLAB8Channel: =>
    for i = 1,@numPixels
      if @getImageChannels() is 4
        alpha = @channelData[i]
        l     = @channelData[i + @channelLength]
        a     = @channelData[i + @channelLength * 2]
        b     = @channelData[i + @channelLength * 3]
      else
        alpha = 255
        l     = @channelData[i]
        a     = @channelData[i + @channelLength]
        b     = @channelData[i + @channelLength * 2]

      rgb = color.labToRGB bit.rshift(l * 100, 8), a - 128, b - 128

      table.insertM(@pixelData, rgb.r, rgb.g, rgb.b, @getAlphaValue(alpha))

  combineLAB16Channel: =>
    for i = 1,@numPixels,2
      if @getImageChannels() is 4
        alpha = @channelData[i]
        l     = @channelData[i + @channelLength]
        a     = @channelData[i + @channelLength * 2]
        b     = @channelData[i + @channelLength * 3]
      else
        alpha = 255
        l     = @channelData[i]
        a     = @channelData[i + @channelLength]
        b     = @channelData[i + @channelLength * 2]

      rgb = color.labToRGB bit.rshift(l * 100, 8), a - 128, b - 128

      table.insertM(@pixelData, rgb.r, rgb.g, rgb.b, @getAlphaValue(alpha))

  combineMultiChannel8: =>
    for i = 1,@numPixels
      c = @channelData[i]
      m = @channelData[i + @channelLength]
      y = @channelData[i + @channelLength * 2]

      if @getImageChannels() is 4
        k = @channelData[i + @channelLength * 3]
      else
        k = 255

      rgb = color.cmykToRGB(255 - c, 255 - m, 255 - y, 255 - k)

      table.insertM(@pixelData, rgb.r, rgb.g, rgb.b, @getAlphaValue(255))