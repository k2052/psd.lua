class PSDBrightnessContrast
  new: (@layer, @length) =>
    @file = @layer.file
    @data = {}

  parse: ->
    @data\brightness = @file\readUInt16()
    @data\contrast   = @file\readUInt16()
    @data\meanValue  = @file\readUInt16()
    @data\labColor   = @file\readUInt16()

    @data