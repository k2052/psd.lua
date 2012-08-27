class PSDLayerEffectCommonStateInfo extends PSDLayerEffect
  parse: => 
    super()
    self\visible = self\file\readBoolean()
    self\file.skip(2)

    return { visible: self\visible }