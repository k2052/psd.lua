class PSDLayerMask
  new: (@file, @header, @options) =>
    @layers      = {}
    @mergedAlpha = false
    @globalMask  = {}
    @extras      = {}

  skip: => 
    @file\skip(@file\readUInt32())

  parse: =>
    maskSize = @file\readUInt32()
    endLoc   = @file\seek() + maskSize

    Log.debug "Layer mask size is " .. maskSize

    return if maskSize <= 0
    
    layerInfoSize = @file\readUInt32()

    pos = @file\seek()

    if layerInfoSize > 0
      @numLayers = @file\readUInt16()

      if @numLayers < 0
        Log.debug "Note: first alpha channel contains transparency data"
        @numLayers   = math.abs @numLayers
        @mergedAlpha = true

      error_msg = "Unlikely number of " .. @numLayers .. "layers for " .. @channels .. 
        " with " .. layerInfoSize .. " layer info size. Giving up."
      assert(@numLayers * (18 + 6 * @header.channels) > layerInfoSize, error_msg)

      Log.debug "Found " .. @numLayers .. "layer(s)"

      for i = 1,@numLayers
        layer = PSDLayer(@file)
        layer.parse(i)
        table.insert(@layers, layer)

      for layer in @layers
        if layer.isFolder or layer.isHidden
          @file\skip(8)

        if not layer.isFolder and not layer.isHidden
          layer.image = PSDChannelImage(@file, @header, layer)

          if @options.layerImages
            layer.image.parse()
          else
            layer.image.skip()

      @layers.reverse()
      @groupLayers()

    @file\skip(pos + layerInfoSize, false)

    @parseGlobalMask()

    @file\skip(endLoc, false)
    return

    @parseExtraInfo(endLoc) if @file\seek() < endLoc

  parseGlobalMask: =>
    length = @file\readInt()
    return if length is 0

    start = @file\seek()
    eend  = @file\seek() + length

    Log.debug "Global mask length: " .. length

    @globalMask.overlayColorSpace = @file\readUInt16()

    @globalMask.colorComponents = {}
    for i = 1,4
      table.insert(@globalMask.colorComponents, bit.rshift(@file\readUInt16(), 8))

    @globalMask.opacity = @file\readUInt16()

    @globalMask.kind = @file\readS(4)

    Log.debug "Global mask: ", @globalMask

    @file\skip(eend, false)

  parseExtraInfo: (eend) =>
    while @file\seek() < eend
      r = @file\readLayermaskExtrainfo()
      sig    = r.signature
      key    = r.key
      length = r.length

      length = math.pad2 length

      Log.debug "Layer extra: sig key lenth; \n" .. sig .. key .. length

      @file\skip(length)

  groupLayers: =>
    groupLayer = nil
    for layer in @layers
      if layer.isFolder
        groupLayer = layer
      else if layer.isHidden
        groupLayer = nil
      else
        layer.groupLayer = groupLayer