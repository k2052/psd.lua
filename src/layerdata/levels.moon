class PSDLevels
  new: (@layer, @length) =>
    @file = @layer.file
    @data =
      records: {}

  parse: =>
    start = @file\seek()

    version = @file\readUInt16()
    assert version == 1

    @parseLevelRecords()

    if @file\seek() - start < @length - 4
      tag = @file\readS(4)
      assert tag == "Lvls"

      version = @file\readUInt16()
      assert version == 3

      @data\levelCount = @file\readUInt32() - 29
      assert @data\levelCount >= 0
      @parseLevelRecords(@data\levelCount)

      return @data

  parseLevelRecords: (count = 29) =>
    for i = 1,count
      record = {}
      results = @file\readLevelrecord()
      for k,v in pairs results do record[k] = v

      record\gamma /= 100

      if i < 27
        assert record\inputFloor    >= 0   and record\inputFloor    <= 255
        assert record\inputCeiling  >= 2   and record\inputCeiling  <= 255
        assert record\outputFloor   >= 0   and record\outputFloor   <= 255
        assert record\outputCeiling >= 0   and record\outputCeiling <= 255
        assert record\gamma         >= 0.1 and record\gamma         <= 9.99

      table.insert(@data\records, record)