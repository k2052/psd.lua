class PSDPosterize
  new: (@layer, @length) =>
    @file = @layer\file
    @data = {}

  parse: =>
    @data\levels = @file\readUInt16()

    assert @data\levels >= 2 and @data\levels <= 255

    @file\skip(2)

   return @data