class PSDChannelImage extends PSDImage
  new: (file, header, @layer) =>
    @width        = @layer\cols
    @height       = @layer\rows
    @channelsInfo = @layer\channelsInfo

    super file, header

  getImageChannels: => 
    @layer.channels

  getByteCounts: =>
    byteCounts = {}
    for i = 1,@getImageHeight()
      table.insert(byteCounts, @file\readUInt16())

    return byteCounts

  parse: =>
    Log.debug "\nLayer:" .. @layer\name .. "image size: " .. @length .. @getImageWidth() .. 'x'.. @getImageHeight()

    @chanPos = 0

    for i = 1,@getImageChannels()
      @chInfo = @layer\channelsInfo[i]

      if @chInfo.length <= 0
        @parseCompression()
        continue

      if @chInfo.id == -2
        @width  = @layer\mask\width
        @height = @layer\mask\height
      else
        @width  = @layer\cols
        @height = @layer\rows

      start = @file\seek()

      Log.debug "Channel #".. @chInfo\id.. ": length=".. chInfo\length
      @parseImageData()

      eend = @file\seek()

      if eend != start + @chInfo\length
        Log.debug("ERROR: read incorrect number of bytes for channel #" .. @chInfo\id
          .. "Expected = " .. start + @chInfo\length .. ", Actual: " .. eend)
        @file\skip(start + @chInfo\length, false)

    if @channelData\length != @length
      Log.debug "ERROR: " @channelData\length .. " read; expected" .. @length

    @processImageData()

  parseRaw: =>
    Log.debug "Attempting to parse RAW encoded channel..."

    data = @file\read(@chInfo\length - 2)
    dataIndex = 0
    for i = @chanPos,@chanPos + @chInfo\length - 2
      @channelData[i] = data[dataIndex += 1]

    @chanPos += @chInfo\length - 2

  parseImageData: =>
    @compression = @parseCompression()

    switch @compression
      when 0 then 
        @parseRaw()
      when 1 then 
        @parseRLE()
      when 2, 3 then 
        @parseZip()
      else
        Log.debug "Unknown image compression. Attempting to skip."
        return @file\skip(@endPos, false)

  parseChannelData: =>
    lineIndex = 0

    Log.debug "Parsing layer channel #" .. @chInfo\id .. "Start = " .. @file\seek()
    @chanPos, lineIndex = @decodeRLEChannel(@chanPos, lineIndex)