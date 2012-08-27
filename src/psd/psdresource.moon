class PSDResource
  @RESOURCE_DESCRIPTIONS = {
    1000: {
      name: 'PS2.0 mode data',
      parse: (self) -> 
        results = @file\readModeData()
        for k,v in pairs results do self[k] = v
      ,
    }

    1001: { 
      name: 'Macintosh print record' 
    },

    1003: { 
      name: 'PS2.0 indexed color table' 
    },

    1005: { 
      name: 'ResolutionInfo' 
    },

    1006: { 
      name: 'Names of the alpha channels' 
    },

    1007: { 
      name: 'DisplayInfo'
    },

    1008: {
      name: 'Caption'
      parse: (self) ->
        @caption = @file\readCstring()
      ,
    },

    1009: {
      name: 'Border information'
      parse: (self) ->
        border_info = @file\readBorderInfo()
        @width  = border_info.width

        @units = switch border_info.units
          when 1 then "inches"
          when 2 then "cm"
          when 3 then "points"
          when 4 then "picas"
          when 5 then "columns"
      ,
    },

    1010: {
      name: 'Background color'
    },

    1011:
      name: 'Print flags'
      parse: (self) ->
        start   = @file\seek()
        results = @file\readPrintFlags()
        for k,v in pairs results do self[k] = v

        @file\seek "set", start + @size

    1012:
      name: 'Grayscale/multichannel halftoning info'

    1013: 
      name: 'Color halftoning info'

    1014:
      name: 'Duotone halftoning info'

    1015:
      name: 'Grayscale/multichannel transfer function'

    1016:
      name: 'Color transfer functions'

    1017: 
      name: 'Duotone transfer functions'

    1018:
      name: 'Duotone image info'

    1019:
      name: 'B&W values for the dot range'
      parse: (self) ->
        @bwvalues = @file\readUInt8()
    1021:
      name: 'EPS options'

    1022: 
      name: 'Quick Mask info'
      parse: (self) ->
        @quickMaskChannelID = @file\readUInt8()
        @wasMaskEmpty       = @file\readUInt(4)
    1024: 
      name: 'Layer state info'
      parse: (self) ->
        @targetLayer = @file\readUInt8()

    1025: 
      name: 'Working path'

    1026: 
      name: 'Layers group info'
      parse: (self) ->
        start = @file\seek()
        @layerGroupInfo = {}
        while @file\seek() < start + @size
          info = @file\readUInt8()
          table.insert(@layerGroupInfo, info)

    1028:
      name: 'IPTC-NAA record (File Info)'

    1029:
      name: 'Image mode for raw format files'

    1030:
      name: 'JPEG quality'

    1032:
      name: 'Grid and guides info'

    1033:
      name: 'Thumbnail resource'

    1034:
      name: 'Copyright flag'
      parse: (self) -> 
        @copyrighted = @file\readBoolean()

    1035:
      name: 'URL'

    1036:
      name: 'Thumbnail resource'

    1037:
      name: 'Global Angle'

    1038:
      name: 'Color samplers resource'

    1039:
      name: 'ICC Profile'

    1040:
      name: 'Watermark'
      parse: (self) ->
        @watermarked = @file\readBoolean()

    1041:
      name: 'ICC Untagged'

    1042:
      name: 'Effects visible'

    1043:
      name: 'Spot Halftone'
      parse: =>

    1044:
      name: 'Document specific IDs seed number'

    1045:
      name: 'Unicode Alpha Names'

    1046:
      name: 'Indexed Color Table Count'

    1047:
      name: 'Transparent Index'

    1049:
      name: 'Global Altitude'

    1050:
      name: 'Slices'

    1051:
      name: 'Workflow URL'

    1052:
      name: 'Jump To XPEP'

    1053:
      name: 'Alpha Identifiers'

    1054:
      name: 'URL List'

    1057:
      name: 'Version Info'

    1058:
      name: 'EXIF data 1'

    1059:
      name: 'EXIF data 3'

    1060:
      name: 'XMP metadata'

    1061:
      name: 'Caption digest'

    1062:
      name: 'Print scale'

    1064:
      name: 'Pixel Aspect Ratio'

    1065:
      name: 'Layer Comps'

    1066:
      name: 'Alternate Duotone Colors'

    1067:
      name: 'Alternate Spot Colors'

    1069:
      name: 'Layer Selection ID(s)'

    1070:
      name: 'HDR Toning information'

    1071:
      name: "Print info"

    1072:
      name: "Layer Groups Enabled"

    1073:
      name: "Color samplers resource"

    1074:
      name: "Measurement Scale"

    1075:
      name: "Timeline Information"

    1076:
      name: "Sheet Disclosure"

    1077:
      name: "DisplayInfo"

    1078:
      name: "Onion Skins"

    1080:
      name: "Count Information"

    1082:
      name: "Print Information"

    1083:
      name: "Print Style"

    1084:
      name: "Macintosh NSPrintInfo"

    1085:
      name: "Windows DEVMODE"

    2999:
      name: 'Name of clipping path'

    7000:
      name: "Image Ready variables"

    7001:
      name: "Image Ready data sets"

    8000:
      name: "Lightroom workflow"

    10000:
      name: 'Print flags info'

  new: (@file) ->

  parse: =>
    @at = @file\seek()

    results = @file\readResourceInfo()
    for k,v in pairs results do self[k] = v

    Log.debug "Resource #" .. @id .. "kind=".. @kind

    @name       = @file\readCstring()
    @name       = @name.substr(0, @name.length - 1)
    @shortName  = @name.substr(0, 20)

    @size = @file\readUInt32()
    @size = math.pad2(@size)

    if 2000 <= @id <= 2998
      @rdesc = "[Path Information]"
      @file\skip @size
    else if @id is 2999
      assert 0
    else if 4000 <= @id < 5000
      @rdesc = "[Plug-in Resource]"
      @file\skip @size
    else if PSDResource.RESOURCE_DESCRIPTIONS[@id]
      resource   = PSDResource.RESOURCE_DESCRIPTIONS[@id]
      @rdesc = "[#{resource.name}]"

      if resource.parse
        resource.parse(self)
      else
        @file\skip @size
    else
      @file\skip @size