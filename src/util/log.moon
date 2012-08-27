
class Log
  @logger: nil 
  @enabled: false

  init: ->
    Log.enabled = true
    Log.logger = logging.file("test%s.log", "%Y-%m-%d")

  info: (msg) ->
    Log.logger:info(msg) if Log.enabled

  debug: (msg, obj) ->
    if Log.enabled
      if type(obj) == 'table'
        Log.logger:debug(msg .. pretty.dump(t))
      else
        Log.logger:debug(msg .. obj) 

  error: (msg) ->
    Log.logger:error(msg) if Log.enabled