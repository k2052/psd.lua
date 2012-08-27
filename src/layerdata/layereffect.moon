class PSDLayerEffect
  new: (@file) =>
  
  parse: =>
    @version = @file\readUInt32()

  getSpaceColor: =>
    @file\skip(2)
    @file\readRGBColorspace()