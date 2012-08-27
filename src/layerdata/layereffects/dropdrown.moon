class PSDDropDownLayerEffect extends PSDLayerEffect
  new: (file, @inner = false) => 
    super(file)
    @data = {}

    @data\blendMode      = "mul"
    @data\color          = @nativeColor = {0,0,0,0}
    @data\opacity        = 191
    @data\angle          = 120
    @data\useGlobalLight = true
    @data\distance       = 5

    @data\spread      = 0
    @data\size        = 5
    @data\antiAliased = false
    @data\knocksOut   = false
 
  parse: =>
    super()
    results = @file\readDropdrowneffect()
    for k,v in pairs(results) do @data[k] = v

    @file\skip(2)

    @data\color     = @file\readRGBColorspace()
    @data\signature = @file\readS(4)
    @data\blendMode = @file\readS(4)

    @data\enabled         = @file\readBoolean()
    @data\useAngleInAllFX = @file\readBoolean()
    
    @data\opacity = @file\readUInt8()
    
    @data\nativeColor = @file\readRGBColorspace() if @version == 2

    return @data