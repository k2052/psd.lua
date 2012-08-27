class PSDHueSaturation
  new: (@layer, @length) =>
    @file = @layer\file

  parse: =>
    version = @file\readUInt16()
    assert version == 2

    @data\colorization = @file\readBoolean()

    @file\seek 1
    @data\hue        = @file\readUInt16()
    @data\saturation = @file\readUInt16()
    @data\lightness  = @file\readUInt16()

    @data\masterHue        = @file\readUInt16()
    @data\masterSaturation = @file\readUInt16()
    @data\masterLightness  = @file\readUInt16()

    @data\rangeValues   = {}
    @data\settingValues = {}
    for i = 1,6
      @data\rangeValues[i]   = {}
      @data\settingValues[i] = {}

      for j = 0,4
        @data\rangeValues[i][j] = @file\readUInt16()

      for j = 0,3
        @data\settingValues[i][j] = @file\readUInt16()

    @data