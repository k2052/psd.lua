class PSDColorBalance
  new: (@layer, @length) =>
    @file = @layer.file
    @data =
      cyanRed: {}
      magentaGreen: {}
      yellowBlue: {}

  parse: =>
    for i = 1,3
      table.insert(@data\cyanRed, @file\readUInt16())
      table.insert(@data\magentaGreen, @file\readUInt16())
      table.insert(@data\yellowBlue, @file\readUInt16())

    @data