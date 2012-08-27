class PSDCurves
  new: (@layer, @length) =>
    @file = @layer\file
    @data =
      curve: {}

  parse: =>
    start = @file\seek()
    @file\skip(1)

    version = @file\readUInt16()
    assert table.contains({1, 4}, version)

    tag = @file\readUInt32()

    @data\curveCount = 0
    for i = 1,32
      if bit.band(tag, bit.lshift(1, i))
        @data\curveCount += 1

    for i = 1,@data\curveCount
      count = 0
      for j = 0,32
        if bit.band(tag, bit.lshift(1, j))
          if count is i
            @data\curve[i] = channelIndex: j
            break

          count += 1

      @data\curve[i].pointCount = @file\readUInt32()
      assert @data\curve[i].pointCount >= 2
      assert @data\curve[i].pointCount <= 19

      for j = 0,@data\curve[i].pointCount
        @data\curve[i].outputValue[j] = @file\readUInt16()
        @data\curve[i].inputValue[j]  = @file\readUInt16()

        assert @data\curve[i].outputValue[j] >= 0
        assert @data\curve[i].outputValue[j] <= 255
        assert @data\curve[i].inputValue[j]  >= 0
        assert @data\curve[i].inputValue[j]  <= 255

    if @file\seek() - start < @length - 4
      tag = @file\readS(4)
      assert tag == 'Crv '

      version = @file\readUInt16()
      assert version is 4

      curveCount = @file\readUInt32()
      assert curveCount == @data\curveCount

      for i = 1,@data\curveCount
        @data\curve[i].channelIndex = @file\readUInt16()
        pointCount                  = @file\readUInt16()
        
        assert pointCount == @data\curve[i].pointCount

        for j = 1,pointCount
          outputValue = @file\readUInt16()
          inputValue  = @file\readUInt16()
          assert outputValue == @data\curve[i].outputValue[j]
          assert inputValue == @data\curve[i].inputValue[j]

   return @data