class PSD
	@version = "0.0.1"
	@debug   = false

	new: (file_object, options) =>
    if options.debug == true
      @debug = true
      Log.init()

		@file      = PSDFile(file_object)
		@header    = nil
    @resources = nil
    @layerMask = nil
    @layers    = nil
    @images    = nil
    @image     = nil

  parse: =>
    Log.debug "Beginning parsing"
    @start_time = os.time()

	  @parseHeader()
    @parseImageResources()
    @parseLayersMasks()
    @parseImageData()

    @end_time = os.time()
    Log.debug "Parsing finished in" .. @end_time - @start_time .. "seconds"

	parseHeader: =>
    Log.debug "\n### Header ###"

		@header = PSDHeader(@file)
		@header.parse()

    Log.debug "Header:\n", @header

  parseImageResources: (skip = false) =>
    Log.debug "\n### Resources ###"

    @resources = {}

    length = @file\readUInt32()
    n      = length

    if skip
      Log.debug "Skipped!"
      return @file\skip(n)

    while n > 0
      pos = @file\seek()

      resource = PSDResource(@file)
      resource.parse()

      n -= @file\seek() - pos
      table.insert(resources, resource)

      Log.debug "Resource: ", resource

    if n != 0
      Log.debug "Image resources overran expected size by: ".. -n .."bytes"
      @file\skip(start + length)

  parseLayersMasks: (skip = false) =>
    @parseHeader() if not @header
    @parseImageResources(true) if not @resources

    Log.debug "\n### Layers & Masks ###"

    @layerMask = PSDLayerMask(@file, @header, @options)
    @layers    = @layerMask.layers

    if skip
      Log.debug "Skipped!"
      @layerMask.skip()
    else
      @layerMask.parse()

  parseImageData: =>
    @parseHeader() if not @header
    @parseImageResources(true) if not @resources
    @parseLayersMasks(true) if not @layerMask

    @image = PSDImage(@file, @header)
    @image.parse()

  getLayerStructure: =>
    @parseLayersMasks() if not @layerMask

    result     = {layers: {}}
    parseStack = {}

    for k,layer in pairs(@layers)
      if layer.isFolder
        table.insert(parseStack, result)
        result = {name: layer.name, layers: {} }
      else if layer.isHidden
        temp   = result
        result = parseStack[table.maxn(parseStack)]
        table.remove(parseStack)
        table.insert(result.layers, temp)
      else
        table.insert(result.layers, layer)

    return result