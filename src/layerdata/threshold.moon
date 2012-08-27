class PSDThreshold
  new: (@layer, @length) =>
    @file = @layer\file
    @data = {}

  parse: =>
    @data\level = @file\readUInt16()
    
    assert @data\level >= 1 and @data\level <= 255

    @file\skip(2)

    @data