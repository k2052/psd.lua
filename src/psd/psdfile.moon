-----
-- PSD File Structures
-----
serial.struct.header = {
  {'sig',               'bytes',  4},
  {'version',           'uint16', 'be'},
  {'reserved',          'bytes',  6},
  {'channels',          'uint16', 'be'},
  {'height',            'uint32', 'be'},
  {'width',             'uint32', 'be'},
  {'depth',             'uint16', 'be'},
  {'color_mode',        'uint16', 'be'}, 
  {'color_data_length', 'uint32', 'be'},
}

serial.struct.mode_data = {
  {'channels', 'uint8', 'be'},
  {'rows',     'uint8', 'be'},
  {'cols',     'uint8', 'be'},  
  {'depth',    'uint8', 'be'},
  {'mode',     'uint8', 'be'},
}

serial.struct.border_info = {
  {'width', 'uint16', 'be'},
  {'units', 'uint8', 'be'},
}

serial.struct.print_flags = {
  {'labels'           ,'uint8', 'be'},               
  {'crop_marks'       ,'uint8', 'be'}, 
  {'color_bars'       ,'uint8', 'be'},  
  {'registratiomarks' ,'uint8', 'be'},  
  {'negative'         ,'uint8', 'be'}, 
  {'flip'             ,'uint8', 'be'}, 
  {'interpolate'      ,'uint8', 'be'}, 
  {'caption'          ,'uint8', 'be'},  
}

serial.struct.resource_info = {
  {'kind',  'bytes',  4},
  {'id',      'uint8', 'be'},
  {'namelen', 'uint8', 'be'},
}

serial.struct.layer_info = {
  {'top',      'uint32', 'be'},
  {'left',     'uint32', 'be'},
  {'bottom',   'uint32', 'be'},
  {'right',    'uint32', 'be'},
  {'channels', 'uint16', 'be'},
}

serial.struct.blendmode_info = {
  {'signature', 'bytes', 4},
  {'key',       'string'},
  {'opacity',   'bytes', 4},
  {'clipping',  'string'},
}

serial.struct.layermask_info = {
  {'top',          'uint32', 'be'},
  {'left',         'uint32', 'be'},
  {'bottom',       'uint32', 'be'},
  {'right',        'uint32', 'be'},
  {'defaultColor', 'uint8',  'be'},
  {'flags',        'uint8',  'be'},
}

serial.struct.levelrecord = {
  {'inputFloor',    'uint16', 'be'},
  {'inputCeiling',  'uint16', 'be'},
  {'outputFloor',   'uint16', 'be'},
  {'outputCeiling', 'uint16', 'be'},
  {'gamma',         'uint16', 'be'},
}

serial.struct.rgbcolorspace = {
  {'red',   'uint16', 'be'},
  {'green', 'uint16', 'be'},
  {'blue',  'uint16', 'be'},
  {'alpha', 'uint16', 'be'},
}

serial.struct.dropdown_effect = {
  {'blur',      'uint16', 'be'},
  {'intensity', 'uint32', 'be'},
  {'angle',     'uint32', 'be'},
  {'distance',  'uint32', 'be'},
}

serial.struct.layermask_extrainfo = {
  {'signature', 'bytes', 4},
  {'key',       'bytes', 4},
  {'length',    'uint32', 'be'},
}

class PSDFile
  new: (file_pointer) =>
    @stream = serial.filestream(file_pointer)
    @log    = logging.file("test%s.log", "%Y-%m-%d")

  readHeader: =>
    serial.read.header(@stream)

  readModeData: =>
    serial.read.mode_data(@stream)

  readPrintFlags: =>
    serial.read.print_flags(@stream)

  readResourceInfo: =>
    serial.read.resource_info(@stream)  

  readLayerInfo: =>
    serial.read.layer_info(@stream)

  readBlendmodeInfo: => 
    serial.read.blendmode_info(@stream)

  readLayermaskInfo: =>
    serial.read.layermask_info(@stream)

  readLevelrecord: =>
    serial.read.levelrecord(@stream)

  readRGBColorspace: =>
    return serial.read.rgbcolorspace(@stream)

  readDropdownEffect: =>
    serial.read.dropdown_effect(@stream)

  readLayermaskExtrainfo: =>
    serial.read.layermask_extrainfo(@stream)

  skipBlock: (reason) -> 
    length = serial.read.uint32(@stream, 'be')
    Log.debug "Skipped " .. desc .. "with" .. length .. "bytes"
    @skip(length)

  skip: (amount, relative = true) =>
    if relative == true
      return serial.skip(@stream, amount)
    else
      return serial.skip(@stream, 'set', amount)

  readInt: =>
    int = @readUInt()
    if int >= 0x80000000 then 
      int - 0x100000000 
    else 
      int

  readUInt: =>
    b1 = bit.lshift(@read(1), 24)
    b2 = bit.lshitf(@read(1), 16)
    b3 = bit.lshitf(@read(1), 8)
    b4 = @read(1)
    return bit.bor(b1, b2, b3, b4)
  
  read: (bytes) =>
    serial.read.bytes(@stream, bytes)

  readS: (bytes) =>
    serial.read.bytes(@stream, bytes)

  readUInt32: =>
    serial.read.uint32(@stream, 'be')

  readCstring: =>
    serial.read.cstring(@stream)

  readBoolean: =>
    serial.read.boolean(@stream)

  readDouble: =>
    serial.read.double(@stream, 'be')

  readDescriptorHead: =>
    -- String
    key = nil
    length = @readInt()
    if length == 0
      rootkey == @readInt()
    else
      rootkey = 0 
      key = @readS(length)

    return length, rootkey, key, @readS(4)

  skipDescriptorHead: =>
    length = @readInt() * 2
    @file\skip(length)

    length = @readInt()
    if length == 0
      @skip(4)
    else
      @file\skip(length)

  readDescriptorKey: (keyCheck = nil) =>
    length = @readUInt32()
    assert length == 0

    key  = @readS(4)
    assert key == keyCheck if keyCheck
    return key

  readObjectPoint: =>
    length = @readUInt32()

    @readDescriptorKey('Pnt ')  

    items = @readUInt32()

    length  = @readUInt32()
    rootkey = @readS(4)
    ostype  = @readS(4)

    horz = nil
    vert = nil

    for i = 1,items
      switch rootkey
        when 'Hrzn' then 
          if ostype == 'UntF'
            key = @readS(4)
            assert key == '#Prc'

          horz = @readDouble()
        when 'Vrtc' then
          if ostype == 'UntF'
            key = @readS(4)
            assert key == '#Prc'

          vert = @readDouble()
        else
          @skipObject(ostype)

    return horz, vert

  readBlendmode: =>
    blend_mode = nil

    length = @readUInt32()

    if length == 0
      tag = @readS(4)
      if table.contains(PSDLayer.BLEND_MODES, tag)
        blend_mode = PSDLayer.BLEND_MODES[tag]
      else
        blend_mode = 'unknown'
    else
      tag = @readS(length)
      if table.contains(PSDLayer.BLEND_MODES, tag)
        blend_mode = PSDLayer.BLEND_MODES[tag]
      else
        blend_mode = 'unknown'

    return blend_mode

  skipObject: (ostype) =>
    switch ostype
      when 'obj ' then
        return @skipObjectReference()
      when 'Objc' then
        return nil
      when 'GlbO' then
        return @skipObjectDescriptor()
      when 'VlLs' then
        return @skipObjectList()
      when 'doub' then
        return @skipObjectDouble()
      when 'UntF' then
        return @skipObjectUnitFloat()
      when 'TEXT' then
        return @skipObjectString()
      when 'enum' then
        return @skipObjectEnum()
      when 'long' then
        return @skipObjectInteger()
      when 'bool' then
        @skipObjectBoolean()
      when 'type' then
        return nil
      when 'GlbC' then
        return @skipObjectClass()
      when 'alis' then
        return @skipObjectAlias()
      else
        return nil

  skipObjectReference: =>
    items = @readUInt32()

    for i = 1,items
      ostype = @readS(4)

      switch ostype
        when 'prop' then
          @skipUnicodeName()
          @skipObjectID()
          @skipObjectID()
        when 'Clss' then
          @skipUnicodeName()
          @skipObjectID()
          @skipObjectID()
        when 'Enmr' then
          @skipUnicodeName()
          @skipObjectID()
          @skipObjectID()
          @skipObjectID()
        when 'rele' then
          @skipUnicodeName()
          @skipObjectID()
          @readInt()
        when 'Idnt' then
          @readInt()
        when 'indx' then
          @readInt()
        when 'name' then
          @skipUnicodeName()

  skipUnicodeName: => @skipObjectString()

  skipObjectString: =>
    length = @readUInt32() * 2
    @skip(length)

  skipObjectDouble: => @skip(8)

  skipObjectUnitFloat: =>
    @readInt()
    @skip(8)

  skipObjectEnum: =>
    @skipObjectID()
    @skipObjectID()

  skipObjectInt: => @readInt()
  skipObjectBoolean: => @readBoolean()

  skipObjectID: =>
    length = @readUInt32()
    if length == 0
      @skip(4)
    else
      @skip(length)

  skipObjectClass: =>
    @skipUnicodeName()
    @skipObjectID()

  skipObjectAlias: =>
    length = @readUInt32()
    @skip(length)

  skipObjectDescriptor: =>
    @skipUnicodeName()
    @skipObjectID()

    items = @readUInt32()

    for i = 1,items
      @skipObjectID()
      ostype = @readS(4)

      @skipObject(ostype)

  skipObjectList: =>
    items = @readUInt32()

    for i = 1,items
      ostype = @readS(4)
      @skipObject(ostype)