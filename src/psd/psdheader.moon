class PSDHeader
  @MODES = {
    0:  'Bitmap',
    1:  'GrayScale',
    2:  'IndexedColor',
    3:  'RGBColor',
    4:  'CMYKColor',
    5:  'HSLColor',
    6:  'HSBColor',
    7:  'Multichannel',
    8:  'Duotone',
    9:  'LabColor',
    10: 'Gray16',
    11: 'RGB48',
    12: 'Lab48',
    13: 'CMYK64',
    14: 'DeepMultichannel',
    15: 'Duotone16',
  }

  new: (@file) =>
  
  parse: =>
	  data = @file\readHeader()

	  for key,value in pairs(data)
		  self[key] = value

    @size = {@rows, @cols]

    assert(@sig == "8BPS", "Not a PSD signature: " .. @sig)
    assert(@version == 1, "Can not handle PSD version " .. @version)

    if 0 <= @color_mode < 16 then
      @color_modename = PSDHeader.MODES[@color_mode]
    else
      @color_modename = "(#{@color_mode})"

    @file\skip(@color_mode_data_length)