class PSDSelectiveColor
  new: (@layer, @length) =>
    @file = @layer\file
    @data =
      cyanCorrection: {}
      magentaCorrection: {}
      yellowCorrection: {}
      blackCorrection: {}

  parse: =>
    version = @file\readUInt16()
    assert version == 1

    @data\correctionMethod = @file\readUInt16()

    for i = 1,10
      table.insert(@data\cyanCorrection, @file\readUInt16())
      table.insert(@data\magentaCorrection, @file\readUInt16())
      table.insert(@data\yellowCorrection, @file\readUInt16())
      table.insert(@data\blackCorrection, @file\readUInt16())

    @data