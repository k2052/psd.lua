class PSDLayer
  @CHANNEL_SUFFIXES =
    '-2': 'layer mask'
    '-1': 'A'
    0: 'R'
    1: 'G'
    2: 'B'
    3: 'RGB'
    4: 'CMYK'
    5: 'HSL'
    6: 'HSB'
    9: 'Lab'
    11: 'RGB'
    12: 'Lab'
    13: 'CMYK'

  @SECTION_DIVIDER_TYPES =
    0: "other"
    1: "open folder"
    2: "closed folder"
    3: "bounding section divider"

  @BLEND_MODES =
    "norm": "normal"
    "dark": "darken"
    "lite": "lighten"
    "hue":  "hue"
    "sat":  "saturation"
    "colr": "color"
    "lum":  "luminosity"
    "mul":  "multiply"
    "scrn": "screen"
    "diss": "dissolve"
    "over": "overlay"
    "hLit": "hard_light"
    "sLit": "soft_light"
    "diff": "difference"
    "smud": "exclusion"
    "div":  "color_dodge"
    "idiv": "color_burn"
    "lbrn": "linear_burn"
    "lddg": "linear_dodge"
    "vLit": "vivid_light"
    "lLit": "linear_light"
    "pLit": "pin_light"
    "hMix": "hard_mix"
    "Nrml": "normal"
    "Dslv": "dissolve"
    "Drkn": "darken"
    "Mltp": "multiply"
    "CBrn": "color_burn"
    "Lghn": "lighten"
    "Scrn": "screen"
    "CDdg": "color_dodge"
    "Ovrl": "overlay"
    "SftL": "soft_light"
    "Hrdl": "hard_light"
    "Dfrn": "difference"
    "Xclu": "exclusion"
    "H   ": "hue"
    "Strt": "saturation"
    "Clr ": "color"
    "Lmns": "luminosity"
    "linearBurn": "linear_burn"
    "linearDodge": "linear_dodge"
    "vividLight": "vivid_light"
    "linearLight": "linear_light"
    "pinLight": "pin_light"
    "hardMix": "hard_mix"

  @BLEND_FLAGS =
    0: "transparency protected"
    1: "visible"
    2: "obsolete"
    3: "bit 4 useful"
    4: "pixel data irrelevant"

  @MASK_FLAGS =
    0: "position relative"
    1: "layer mask disabled"
    2: "invert layer mask"

  @SAFE_FONTS = {
    "Arial",
    "Courier New",
    "Georgia",
    "Times New Roman",
    "Verdana",
    "Trebuchet MS",
    "Lucida Sans",
    "Tahoma",
  }

  new: (@file, @header = nil) =>
    @image          = nil
    @mask           = {}
    @blendingRanges = {}
    @adjustments    = {}

    @layerType     = "normal"
    @blendingMode  = "normal"
    @opacity       = 255
    @fillOpacity   = 255

    @isFolder = false
    @isHidden = false

  parse: (layerIndex = nil) =>
    @parseInfo(layerIndex)
    @parseBlendModes()

    extralen      = @file\readUInt32()
    @layerEnd = @file\seek() + extralen

    assert extralen > 0

    extrastart = @file\seek()

    result = @parseMaskData()
    if not result
      Log.debug "Error parsing mask data for layer " .. layerIndex .. ". Skipping."
      return @file\skip(@layerEnd, false)

    @parseBlendingRanges()
    @parseLayerName()
    @parseExtraData()

    @file\skip(extrastart + extralen, false)

  parseInfo: (layerIndex) =>
    @idx = layerIndex

    results = @file\readLayerInfo()
    for k,v in pairs results do self[k] = v
    
    @rows = @bottom - @top 
    @cols = @right - @left

    assert @channels > 0

    @height = @rows
    @width  = @cols

    if @bottom < @top or @right < @left or @channels > 64
      Log.debug "Somethings not right, attempting to skip layer."

      @file\skip(6 * @channels + 12)
      @file\skipBlock("layer info: extra data")
      return 

    @channelsInfo = {}
    for i = 1,@channels
      channelID     = @file\readUInt16()
      channelLength = @file\readUInt32()
      Log.debug "Channel " .. i .. ": id=" .. channelID .. ", " .. channelLength .. " bytes, type=" .. PSDLayer.CHANNEL_SUFFIXES[channelID]

      table.insert(@channelsInfo, {id: channelID, length: channelLength })
    
  parseBlendModes: =>
    @blendmode = {}

    results = @file\readBlendmodeInfo()
    for k,v in pairs results do self[k] = v

    flags = @file\readUInt8()

    assert @blendmode.sig == "8BIM"

    @blendmode.key               = @blendmode.key.trim()
    @blendmode.opacityPercentage = (@blendmode.opacity * 100) / 255
    @blendmode.blender           = PSDLayer.BLEND_MODES[@blendmode.key]

    @blendmode.transparencyProtected = bit.band(flags, 0x01)
    @blendmode.visible               = bit.band(flags, bit.lshift(0x01, 1)) > 0
    @blendmode.visible               = 1 - @blendmode.visible
    @blendmode.obsolete              = bit.band(flags, bit.lshift(0x01,2)) > 0
    
    if bit.band(flags, bit.lshift(0x01, 3)) > 0
      @blendmode.pixelDataIrrelevant = bit.band(flags, bit.lshift(0x01,4)) > 0

    @blendingMode = @blendmode.blender
    @opacity      = @blendmode.opacity

    Log.debug "Blending mode: ", @blendMode

  parseMaskData: =>
    @mask.size = @file\readUInt32()

    assert table.contains({36, 20, 0}, @mask.size)

    return true if @mask.size == 0
    
    results = @file\readLayermaskInfo()
    for k,v in pairs results do @mask[k] = v

    assert table.contains({0, 255}, @mask.defaultColor)

    @mask.width  = @mask.right  - @mask.left
    @mask.height = @mask.bottom - @mask.top

    @mask.relative = bit.band(flags,0x01)
    @mask.disabled = bit.band(flags, bit.lshift(0x01, 1)) > 0
    @mask.invert   = bit.band(flags, bit.lshift(0x01, 2)) > 0

    if @mask.size is 20
      @file\skip(2)
    else
      flags                  = @file\readUInt8()
      @mask.defaultColor = @file\readUInt8()

      @mask.relative = bit.band(flags, 0x01)
      @mask.disabled = bit.band(flags, bit.lshift(0x01, 1)) > 0
      @mask.invert   = bit.band(flags, bit.lshift(0x01, 2)) > 0

      @file\skip(16)

    return true

  parseBlendingRanges: =>
    length = @file\readUInt32()

    @blendingRanges.grey =
      source:
        black: @file\readUInt16()
        white: @file\readUInt16()
      dest:
        black: @readUInt16()
        white: @readUInt16()

    pos = @file\seek()

    @blendingRanges.numChannels = (length - 8) / 8
    assert @blendingRanges.numChannels > 0

    @blendingRanges.channels = {}
    for i = 1,@blendingRanges.numChannels
      t = 
        source: 
          black: @file\readUInt16()
          white: @file\readUInt16()
        dest: 
          black: @file\readUInt16()
          white: @file\readUInt16()

      table.insert(@blendingRanges.channels, t)

  parseLayerName: =>
    namelen    = @file\readUInt32()
    @name  = @file\readCstring(namelen)

    Log.debug "Layer name: " .. @name

  parseExtraData: =>
    while @file\seek() < @layerEnd
     signature = @file\readS(4)
     key       = @file\readS(4)

      assert signature == "8BIM"

      leng th = @file\readUInt32()
      pos     = @file\seek()

      Log.debug "Extra layer info: key = " .. key .. ", length = " .. length
      switch key
        when "levl"
          @adjustments.levels = PSDLevels(self, length).parse
        when "curv"
          @adjustments.curves = PSDCurves(self, length).parse()
        when "brit"
          @adjustments.brightnessContrast = PSDBrightnessContrast(self, length).parse()
        when "blnc"
          @adjustments.colorBalance = PSDColorBalance(self, length).parse()
        when "hue2"
          @adjustments.hueSaturation = PSDHueSaturation(self, length).parse()
        when "selc"
          @adjustments.selectiveColor = PSDSelectiveColor(self, length).parse()
        when "thrs"
          @adjustments.threshold = PSDThreshold(self, length).parse()
        when "nvrt"
          @adjustments.invert = PSDInvert(self, length).parse()
        when "post"
          @adjustments.posterize = PSDPosterize(self, length).parse()
        when "lyid"
          @layerId = @file\readUInt32()
        when "lsct"
          @readLayerSectionDivider()
        when "lrFX"
          @parseEffectsLayer() 
          @file\skip(2)
        when "lfx2"
          @parseLayerStyles()
        else  
          @file\skip(length)
          Log.debug "Skipping additional layer info with key " .. key


      if @file\seek() != (pos + length)
        Log.debug "Error parsing additional layer info with key " .. key .. " - unexpected end"
        @file\skip(pos + length, false)

  parseEffectsLayer: =>
    effects = {}

    v     = @file\readUInt16()
    count = @file\readUInt16()

    while count > 0
      signature = @file\readS(4)
      key       = @file\readS(4)

      size = @file\readUInt32()

      pos = @file\seek()

      Log.debug "Parsing effect layer with type " .. key .. "and size " .. size

      effect =    
        switch key
          when "cmnS" then PSDLayerEffectCommonStateInfo(@file)
          when "dsdw" then PSDShadowLayerEffect(@file)
          when "isdw" then PSDShadowLayerEffect(@file, true)
          -- when "oglw" then new PSDGlowLayerEffect @file
          -- when "iglw" then new PSDGlowLayerEffect @file, true

      data = effect.parse() if effect

      left = (pos + size) - @file\seek()

      if left != 0
        Log.debug "Failed to parse effect layer with type " .. key
        @file\skip(left)
      else
        table.insert(effects, data) if key != "cmnS"

    @adjustments.effects = effects

  parseLayerStyles: =>
    styles = {}

    v     = @file\readUInt16()
    count = @file\readUInt16()

    while count > 0
      signature = @file\readS(4)
      key       = @file\readS(4)

      size = @file\readUInt32()

      pos = @file\seek()

      style =    
        switch key
          when "DrSh" then PSDShadowLayerStyle(@file)
          when "IrSh" then PSDInnerShadowLayerStyle(@file)
          when "OrGl" then PSDGlowLayerStyle(@file)
          when "IrGl" then PSDInnerGlowLayerStyle(@file, true)
          when "GrFl" then PSDGradientLayerStyle(@file)
          when "FrFX" then PSDStrokeLayerStyle(@file)

      data = style.parse() if style

      left = (pos + size) - @file\seek()

      if left != 0
        @file\skip(left)
      else
        table.insert(styles, data) if key != "cmnS"

    @styles = styles

  readLayerSectionDivider: =>
    code           = @file\readUInt32()
    @layerType = PSDLayer.SECTION_DIVIDER_TYPES[code]

    switch code
      when 1 or 2 then @isFolder = true
      when 3 then @isHidden = true