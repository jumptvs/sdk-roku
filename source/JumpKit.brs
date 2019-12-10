function JumpKitLogger() as object
  logger = {
    prefix: "[JumpKit]"
  }

  logger.debug = function(message as string) as void
    m.printLog("[DEBUG] ", message)
  end function

  logger.info = function(message as string) as void
    m.printLog("[INFO] ", message)
  end function

  logger.error = function(message as string) as void
    m.printLog("[ERROR] ", message)
  end function

  logger.printLog = function(level as string, message as string) as void
    debugMode = JumpKitInstance()._internal.config.debugMode

    if debugMode = "true"
      print m.prefix + level + message
    end if
  end function

  return logger
end function

function JumpKitShemas() as Object
  schemas = {}

  schemas.userInfo = {
    type: "object",
    fields: [
      {
        name: "userId", required: false, type: "string"
      }
      {
        name: "userType", required: true, type: "string", options: {"anonymous": 0, "registered user": 0, "mvpd": 0}
      }
      {
        name: "userBirthDate", required: false, type: "string"
      }
      {
        name: "userCountry", required: false, type: "string"
      }
      {
        name: "userSex", required: false, type: "string"
      }
      {
        name: "userProfileId", required: false, type: "string"
      }
      {
        name: "userOperator", required: false, type: "string"
      }
    ]
  }

  schemas.contentInfo = {
    type: "object"
    fields: [
      {
        name: "contentId", required: true, type: "string"
      }
      {
        name: "contentTitle", required: false, type: "string"
      }
      {
        name: "episodeNumber", required: false, type: "integer"
      }
      {
        name: "seasonNumber", required: false, type: "integer"
      }
      {
        name: "contentDescription", required: false, type: "string"
      }
      {
        name: "contentGenres", required: false, type: "array",
        fields: [
          {
            name: "genreId", required: true, type: "string"
          }
          {
            name: "genreName", required: false, type: "string"
          }
          {
            name: "genreCategory", required: false, type: "object",
            fields: [
              {
                name: "categoryId", required: true, type: "string"
              }
              {
                name: "categoryName", required: true, type: "string"
              }
            ]
          }
          {
            name: "genreSubCategory", required: false, type: "object",
            fields: [
              {
                name: "categoryId", required: true, type: "string"
              }
              {
                name: "subcategoryId", required: true, type: "string"
              }
              {
                name: "subcategoryName", required: true, type: "string"
              }
            ]
          }  
        ]
      }
      {
        name: "contentProvider", required: false, type: "string"
      }
      {
        name: "contentTransactionType", required: false, type: "integer"
      }
      {
        name: "contentType", required: false, type: "integer"
      }
      {
        name: "contentLanguage", required: false, type: "string"
      }
    ]
  }

  schemas.playerInfo = {
    name: "playerInfo", required: true, type: "object",
    fields: [
      {
        name: "playbackSession", required: true, type: "string"
      }
      {
        name: "content", required: true, type: "object", fields: schemas.contentInfo.fields
      }
      {
        name: "contentId", required: true, type: "string"
      }
			{
        name: "currentTime", required: true, type: "integer"
      }
			{
        name: "totalTime", required: true, type: "integer"
      }
			{
        name: "playerType", required: true, type: "integer"
      }
			{
        name: "contextData", required: false, type: "object", fields: [
          {
            name: "playerInterval", required: false, type: "integer"
          }
          {
            name: "playerBitrate", required: false, type: "double"
          }
          {
            name: "timeshift", required: false, type: "integer"
          }
        ]
      }
    ]
  }

  return schemas
end function

function JumpKitObtainSchema(categoryType as integer, eventType as integer) as object
  constants = JumpKitConstants()
  schemas = JumpKitShemas()
  if categoryType = constants.categories.player
    return schemas.playerInfo
  end if
end function

function JumpKitSchemaCheck(schema as object, event as object, root as boolean) as string
  validatorTypes = JumpKitSchemaValidatorFunctions()
  messageError = ""
  eventFields = event

  if root = true and schema.name <> invalid
    if event[schema.name] = invalid
      return "the field '" + schema.name + "' is required"
    end if
    
    if validatorTypes["is" + schema.type](event) = false
      return "the field '" + schema.name + "' must be of type '" + schema.type + "' and not of type '" + LCase(type(event)) + "'"
    end if
    eventFields = event[schema.name]
  end if

  if schema.fields <> invalid
    for each field In schema.fields
      ' Check for required fields
      if field.required = true
        if eventFields[field.name] = invalid
          messageError = "the field '" + field.name + "' is required"
          exit for
        end if
      end if

      fieldValue = eventFields[field.name]

      ' check the value is valid
      if field.options <> invalid
        if field.options[fieldValue] = invalid
          messageError = "the field '" + field.name + "' is incorrect"
          exit for
        end if
      end if

      ' Check the type
      if fieldValue <> invalid and validatorTypes["is" + field.type](fieldValue) = false
        messageError = "the field '" + field.name + "' must be of type '" + field.type + "' and not of type '" + LCase(type(fieldValue)) + "'"
        exit for
      end if

      ' Checks the schema of each element in an array
      if fieldValue <> invalid and field.type = "array"
        for each elementValue In fieldValue
          messageError = JumpKitSchemaCheck({ type: field.type, fields: field.fields }, elementValue, false)
          if Len(messageError) > 0
            exit for
          end if
        end for
      end if

      ' Check the schema
      if fieldValue <> invalid and field.type = "object"
        messageError = JumpKitSchemaCheck({ type: field.type, fields: field.fields }, fieldValue, false)
        if Len(messageError) > 0
          exit for
        end if
      end if
    end for
  end if

  return messageError
end function

function JumpKitSchemaValidatorFunctions() as object
  validator = {

    isInteger : function(input as object) as boolean
      return input <> invalid and (LCase(type(input)) = "roint" or LCase(type(input)) = "rolonginteger" or LCase(type(input)) = "integer" or LCase(type(input)) = "longinteger")
    end function

    isDouble : function(input as object) as boolean
      return input <> invalid and (LCase(type(input)) = "double" or LCase(type(input)) = "rodouble")
    end function

    isBoolean : function(input as object) as boolean
      return input <> invalid and (LCase(type(input)) = "roboolean" or LCase(type(input)) = "boolean")
    end function

    isObject : function(input as object) as boolean
      return input = invalid or (LCase(type(input)) = "roassociativearray" or LCase(type(input)) = "array")
    end function

    isString : function(input as object) as boolean
      return input <> invalid and (LCase(type(input)) = "rostring" or LCase(type(input)) = "string")
    end function

    isArray : function(input as object) as boolean
      return input <> invalid and (LCase(type(input)) = "roarray" or LCase(type(input)) = "array")
    end function
  }

  return validator
end function

function JumpKitConstants() as Object
  insights = {
    "eventTypes": {
      "manual": 0,
      "automatic": 1,
      "videoTracking": 2
    },
    "categories": {
      ' User related category
      "user": 1000,
      ' Applocation related category
      "application": 2000,
      ' Applciation menu related category.
      "menu": 3000,
      ' Navigation related category.
      "navigation": 4000,
      ' Electronic programming guide related category.
      "epg": 5000,
      ' Personal recordings related category.
      "recordings": 6000,
      ' Live tv related category.
      "linearTV": 7000,
      ' Click / Touch related category.
      "click": 8000,
      ' Purchase related category.
      "purchase": 9000,
      ' Playback related category.
      "player": 10000,
      ' Error category. (Emitted in case SDK internal inconsistency)
      "error": 11000,
      ' Search related category.
      "search": 12000
    },
    "events": {
      ' User event type.
      "user": {
        ' User registration event
        "registration": 1001,
        ' User login event.
        "login": 1002,
        ' User logout event.
        "logout": 1003,
        ' User cancellation event.
        "cancellation": 1004,
        ' Profile selection event.
        "choseUserProfile": 1005
      },

      ' Application event type. (emitted automatically)
      "application": {
        ' Applciation started. (emitted right after SDK is initialized).
        "started": 2001,
        ' Application went to background.
        "background": 2002,
        ' Applicaion went to foreground.
        "foreground": 2003,
        ' Application is going to be terminated by the system.
        "terminated": 2004
      },

      ' Menu event type.
      "menu": {
        ' Menu openned event
        "open": 3001,
        ' Menu closed event
        "close": 3002,
        ' Menu item selection event
        "itemSelection": 3003
      },

      ' Navigation event type.
      "navigation": {
        ' Navigation to home.
        "home": 4001,
        ' Navigation to all genres page.
        "allGenresPage": 4002,
        ' Navigation to category
        "category": 4003,
        ' Navigation to subcategory
        "subCategory": 4004,
        ' Navigation to genre.
        "genre": 4005,
        ' Naviation to content details page
        "contentDetails": 4006,
        ' Navigation to electronic programming guide.
        "epg": 4007,
        ' Navigation to live tv.
        "live": 4008,
        ' Naviation to linear.
        "linear": 4009,
        ' Navigation to lapsed.
        "lapsed": 4010,
        ' Navigation to catchup.
        "catchUp": 4011,
        ' Navigation to personal recordings.
        "recordings": 4012,
        ' Navigation to promotion page. * * JKContextPromotion * * context.
        "promotionPage": 4013
      },

      ' Electronic programming guide event type.
      "epg": {
        ' Epg content changed
        "contentChanged": 5001,
        ' Epg content selected
        "contentSelected": 5002,
      },

      ' Recordings event type.
      "recordings": {
        ' Recording selected
        "recContentSelected": 6001,
        ' Full content selected
        "fullContentSelected": 6002,
      },

      ' Live tv event type
      "linearTV": {
        ' Live tv channel changed
        "channelChanged": 7001
      },

      ' Click event type.
      "click": {
        ' Play button cliked
        "playButton": 8001,
        ' Promotion banner cliked
        "promotionBanner": 8002,
        ' Promotion cliked
        "promotion": 8003
      },

      ' Purchase event type.
      "purchase": {
        ' Item purchased
        "item": 9001,
        ' Plan purchased
        "upgradePlan": 9002
      },

      ' Player event type. This events are emitted by JumpKit player extensions.
      "player": {
        ' Player item initial bitrate
        "playbackBitrateStarted": 10001,
        ' Player item bitrate changed
        "playbackBitrateChanged": 10002,
        ' Player item initial buffering interval
        "playbackBufferingInterval": 10003,
        ' Player item rebuffering interval during playback
        "playbackReBufferingInterval": 10004,
        ' Player item playback started event
        "playbackStarted": 10005,
        ' Player item total playback interval
        "playbackInterval": 10006,
        ' Player playback paused
        "playbackPaused": 10007,
        ' Player item playback ended
        "playbackEnded": 10008,
        ' Player / Player item playback error
        "playbackError": 10009,
        ' Player exit
        "playerExit": 10010,
        ' Player seek event
        "playbackSeek": 10011,
        ' Player custom event
        "playerCustomEvent": 10012,
        ' Player timeshift event
        "playbackTimeshift": 10013
      },

      ' Search event type.
      "search": {
        ' Search action event
        "searchedContent": 12001,
        ' Search result item clicked event
        "searchResultClicked": 12002
      }
    },
    "user": {
      "sex": {
        "male": "male",
        "female": "female",
      },
      "type": {
        "anonymous": "anonymous"
        "registered": "registered user",
        "mvpd": "mvpd"
      }
    },
    "contentInfo": {
      "contentType": {
        "undefined": -1,
        "trailer": 0,
        "episode": 1,
        "movie": 2,
        "broadcast": 3,
        "sport": 4,
        "other": 5
      },
      "transactionType": {
        "undefined": -1,
        "transactional": 0,
        "rental": 1,
        "subscription": 2,
        "free": 3
      },
    }
  }

  constants = {
    insights: insights
  }

  return constants
end function

function JumpKitUtilities()
  utilities = {
    timeZoneOffset: function() as longinteger
      date = CreateObject("roDateTime")
      seconds = date.GetTimeZoneOffset() * 60 * 1000
      seconds = -seconds

      return seconds
    end function
    
    unixTime: function() as longinteger
      time = CreateObject("roDateTime")

      milliseconds = time.AsSeconds() * 1000& + time.getMilliseconds()

      return milliseconds
    end function

    isEmpty: function(input as dynamic) as boolean
      return input = invalid or len(input) = 0
    end function
  }

  return utilities
end function

function JumpKitStarted() as boolean
  appInfo = CreateObject("roAppInfo")

  if MatchFiles("tmp:/", "jdkStarted_" + appInfo.getid()).Count() = 0
    WriteAsciiFile("tmp:/jdkStarted_" + appInfo.getid(), "")
    return false
  end if

  return true
end function

function JumpKitStorage()
  appInfo = CreateObject("roAppInfo")
  storage = {}

  storage.keys = {
    STORAGE_NAME: "jumpKitStorage_" + appInfo.getid(),
    STORAGE_INSIGHTS_NAME: "jumpKitInsightsStorage_" + appInfo.getid(),
    INSTALLATION_ID: "installationId",
    INSIGHTS_USER_INFO: "userInfo",
    APP_KEY: "appKey",
    DEBUG_MODE: "debugMode"
  }
  
  storage.bucket = CreateObject("roRegistrySection", storage.keys.STORAGE_NAME)
  storage.InsightsEventsBucket = CreateObject("roRegistrySection", storage.keys.STORAGE_INSIGHTS_NAME)

  storage.add = function(key as String, value as String) as Boolean
    return m.bucket.Write(key, value)
  end function

  storage.get = function(key as string) as string
    return m.bucket.Read(key)
  end function

  storage.destroy = function(key as string) as boolean
    return m.bucket.Delete(key)
  end function

  storage.exist = function(key as string) as boolean
    return m.bucket.Exists(key)
  end function

  storage.getInsightsEvents = function() as Object
    eventsKeys = m.InsightsEventsBucket.GetKeyList()
    events = []

    for each eventKey in eventsKeys
      event = m.InsightsEventsBucket.Read(eventKey)
      events.push(ParseJson(event))
    end for

    return events
  end function

  storage.addInsightsEvent = function(event as Object) as Boolean
    eventJson = FormatJSON(event)
    key = StrI(event.metadata.dateTime)
    return m.InsightsEventsBucket.Write(key, eventJson)
  end function

  storage.cleanInsightsEvents = sub(events as Object)
    for each event in events
      eventKey = StrI(event.metadata.dateTime)
      m.InsightsEventsBucket.Delete(eventKey)
    end for
  end sub

  return storage
end function

function JumpKitInstance() as Object
  if (getGlobalAA().jumpKitInstance = invalid) then
    print "[JumpKit][Error] JumpKitInstance() called prior to JumpKit()"
  end if
  return getGlobalAA().jumpKitInstance
end function

function JumpKit() as Object
  if (getGlobalAA().jumpKitInstance <> invalid) then
    instance = JumpKitInstance()
    ' instance._internal.logger.debug("Reuse the instance of JumpKit")
    return instance
  end if

  logger = JumpKitLogger()
  utilities = JumpKitUtilities()
  storage = JumpKitStorage()
  roDeviceInfo = CreateObject("roDeviceInfo")

  if storage.exist(storage.keys.INSTALLATION_ID) = false then
    storage.add(storage.keys.INSTALLATION_ID, roDeviceInfo.getRandomUUID())
  end if

  config = {
    version: "1.0.7",
    urlInsightsAPI: "https://jdkapi.jumptvs.com/v1/production/events",
    appKey: "",
    port: createObject("roMessagePort"),
    debugMode: "false"
  }

  sync = sub()
    internal = JumpKitInstance()._internal
    events = internal.storage.getInsightsEvents()

    if events.Count() = 0
      internal.logger.info("There are no pending events")
      return
    end if

    internal.logger.info("events to send " + StrI(events.Count()))

    request = CreateObject("roUrlTransfer")
    request.SetUrl(internal.config.urlInsightsAPI)

    headers = {
      "Content-Type": "application/json",
      "Authorization": internal.config.appKey
    }

    request.SetHeaders(headers)
    request.setRequest("POST")
    request.setMessagePort(internal.config.port)
    request.setCertificatesFile("common:/certs/ca-bundle.crt")
    request.initClientCertificates()

    body = FormatJSON(events)

    response = request.AsyncPostFromString(body)
    timeout = 30000

    if response then
      msg = wait(timeout, internal.config.port)
      if type(msg) = "roUrlEvent" then
        statusCode = msg.GetResponseCode()
        body = msg.GetString()
        bodyJson = ParseJSON(body)

        if statusCode <> 200
          internal.logger.error("Error response when sending data")
          internal.storage.cleanInsightsEvents(events)
          return
        end if

        if bodyJson.FailedRecordCount <> 0
          internal.logger.error("Some event does not correspond to the schema")
        else
          internal.storage.cleanInsightsEvents(events)
        end if
      end if
    end if

    insights = {}
    insights.schemas = function(categoryType as Integer, eventType as integer)
      constants = JumpKitConstants()
      insights = constants.insights
      categories = insights.categories

      if categoryType = categories.player
        if eventType = insights.playerEventType.playbackStarted
        end if
      end if
    end function
  end sub

  public = {
    startWithAppKey: sub(appKey as string)
      internal = JumpKitInstance()._internal

      internal.logger.info("Welcome Jump Kit SDK V" + internal.config.version)
      
      internal.config.appKey = appKey

      if Len(internal.storage.get(internal.storage.keys.APP_KEY)) = 0
        constants = JumpKitConstants()
        insights = JumpKitInstance().insights
        insights.track(constants.insights.categories.application, constants.insights.events.application.started, {})
      end if

      internal.storage.add(internal.storage.keys.APP_KEY, appKey)
    End Sub

    getInstallationId: function() as Dynamic
      storage = JumpKitInstance()._internal.storage
      return storage.get(storage.keys.INSTALLATION_ID)
    end function

    setDebug: sub(debug as boolean)
      internal = JumpKitInstance()._internal
      storage = internal.storage
      config = internal.config

      if debug = true
        storage.add(storage.keys.DEBUG_MODE, "true")
        config.debugMode = "true"
      else
        storage.add(storage.keys.DEBUG_MODE, "false")
        config.debugMode = "false"
      end if
    end sub

    insights: {
      _tracking: {
        "playbackStartTime": 0
      }

      _contentInfo: {
        "contentId": "unknown"
      }

      _userInfo: {
        "userType": "anonymous"
      }

      _playbackIntervalBenchmarkInit: sub()
        date = CreateObject("roDateTime")
        m._tracking.playbackStartTime = date.asSeconds()
      end sub

      _playbackIntervalBenchmarkStop: function()
        seconds = 0

        if m._tracking.playbackStartTime > 0
          date = CreateObject("roDateTime")
          seconds = date.asSeconds() - m._tracking.playbackStartTime
        end if
        
        m._tracking.playbackStartTime = 0

        return seconds
      end function

      _playbackBufferingBenchmarkInit: sub()
        date = CreateObject("roDateTime")
        m._tracking.bufferingStartTime = date.asSeconds()
      end sub

      _playbackBufferingBenchmarkStop: function()
        seconds = 0

        if m._tracking.bufferingStartTime > 0
          date = CreateObject("roDateTime")
          seconds = date.asSeconds() - m._tracking.bufferingStartTime
        end if

        m._tracking.bufferingStartTime = 0

        return seconds
      end function

      setUserInfo: function(userInfo as dynamic) as object
        internal = JumpKitInstance()._internal

        if userInfo = invalid
          m._userInfo = {
            "userType": "anonymous"
          }

          internal.storage.add(internal.storage.keys.INSIGHTS_USER_INFO, FormatJSON(m._userInfo))

          return true
        end if

        if userInfo.userType <> "anonymous"
          userInfoSchema = JumpKitShemas().userInfo

          message = JumpKitSchemaCheck(userInfoSchema, userInfo, false)

          if Len(message) > 0
            internal.logger.error(message)
            return false
          end if

          m._userInfo = userInfo

          internal.storage.add(internal.storage.keys.INSIGHTS_USER_INFO, FormatJSON(userInfo))

          return true
        end if

        return false
      end function

      track: Function(categoryType as Integer, eventType as Integer, eventContextInformation as Object)
      
        internal = JumpKitInstance()._internal
        constants = JumpKitConstants()

        eventToSend = {
          "event": eventType,
          "category": categoryType,
          "metadata": {
            "JUMP-APP-KEY": internal.config.appKey,
            "dateTime": internal.utilities.unixTime(),
            "eventType": constants.insights.eventTypes.manual,
            "userInfo": m._userInfo,
            "deviceInfo": internal.models.deviceInfo()
            "jdk": {
              "ecosystem": "roku",
              "version": internal.config.version
            }
          },
          "contextInformation": eventContextInformation
        }

        internal.logger.info("Track Event category type:" + StrI(categoryType) + " event type:" + StrI(eventType) + " event:" + FormatJSON(eventToSend))
        
        return internal.storage.addInsightsEvent(eventToSend)
      End Function


      setContent: sub(contentInfo as object)
        contentInfoSchema = JumpKitShemas().contentInfo
        
        checkResult = JumpKitSchemaCheck(contentInfoSchema, contentInfo, false)
        if Len(checkResult) = 0
          m._contentInfo = contentInfo
        else
          internal = JumpKitInstance()._internal
          internal.logger.error(checkResult)

          m._contentInfo = {
            "contentId": "unknown"
          }
        end if
      end sub

      trackTimeshiftEvent: sub(timeshift as integer)
        constants = JumpKitConstants()
        event = jumpKitPlayerTimeshiftContext(constants.insights.categories.player, constants.insights.events.player.playbackTimeshift, timeshift, m._tracking.playbackSession, m.currentVideoPlayer)
        m.track(event)
      end sub

      setVideoPlayer: sub(videoPlayer as Dynamic)

        if videoPlayer = invalid

          if m._tracking.playbackSession <> invalid

            m.currentVideoPlayer.unobserveField("state")
            m.currentVideoPlayer.unobserveField("streamInfo")

            constants = JumpKitConstants()
            contextInformation = jumpKitPlayerContext({}, m._tracking.playbackSession, m.currentVideoPlayer)

            contextData = invalid
            jumpKitSendPlaybackIntervalIfNeeded(constants.insights.categories.player, constants.insights.events.player.playbackInterval, m._playbackIntervalBenchmarkStop(), contextData, m._tracking.playbackSession, m.currentVideoPlayer)
            m.track(constants.insights.categories.player, constants.insights.events.player.playerExit, contextInformation)

            m._contentInfo = {
              "contentId": "unknown"
            }
          end if

          return
        end if

        m._tracking = {
          "playbackStartTime": 0
        }

        roDeviceInfo = CreateObject("roDeviceInfo")

        videoPlayer.observeField("state", "jumpKitPlayerOnStateChange")
        videoPlayer.notificationInterval = 1

        m.currentVideoPlayer = videoPlayer
        m._tracking.playbackSession = roDeviceInfo.getRandomUUID()
      end sub
    }
  }
  
  internalApi = {
    models: {
      "deviceInfo": function() as object
        internal = JumpKitInstance()._internal

        roDeviceInfo = CreateObject("roDeviceInfo")

        displaySize = roDeviceInfo.GetDisplaySize()
        deviceInfo = {
          "deviceUdid": internal.storage.get(internal.storage.keys.INSTALLATION_ID)
          "devicePlatform": "roku"
          "deviceModel": roDeviceInfo.GetModel()
          "deviceFormFactor": roDeviceInfo.GetModelType()
          "screenWidth": Str(displaySize["w"])
          "screenHeight": Str(displaySize["h"])
          "timeZoneOffset": internal.utilities.timeZoneOffset()
        }

        return deviceInfo
      end function
    }
    utilities: utilities,
    logger: logger,
    storage: storage,
    config: config,
    sync: sync
  }

  public._internal = internalApi
  getGlobalAA().jumpKitInstance = public

  if JumpKitStarted() = true
    config.appKey = storage.get(storage.keys.APP_KEY)

    userInfoString = storage.get(storage.keys.INSIGHTS_USER_INFO)
  
    if Len(userInfoString) > 0
      public.insights._userInfo = ParseJson(userInfoString)
    end if
    
    config.debugMode = storage.get(storage.keys.DEBUG_MODE)
  else
    storage.destroy(storage.keys.APP_KEY)
    storage.destroy(storage.keys.INSIGHTS_USER_INFO)
    storage.add(storage.keys.DEBUG_MODE, "false")
  end if

  return public
end function

sub jumpKitPlayerOnStateChange()
  insights = JumpKitInstance().insights
  internal = JumpKitInstance()._internal

  video = insights.currentVideoPlayer
  playbackSession = insights._tracking.playbackSession

  constants = JumpKitConstants()

  if video.content <> invalid
    state = video.state
    contextData = invalid
    categoryType = constants.insights.categories.player

    internal.logger.debug("[VideoPlayer] state -> " + state)

    if state = "buffering"
      insights._tracking.hasBecomeBuffering = true
      insights._playbackBufferingBenchmarkInit()
    else if state = "playing"
      bufferingEventType = constants.insights.events.player.playbackReBufferingInterval

      if insights._tracking.rebuffering = invalid then
        insights._tracking.rebuffering = true
        bufferingEventType = constants.insights.events.player.playbackBufferingInterval
      end if

      if insights._tracking.hasBecomeBuffering = true
        insights._tracking.hasBecomeBuffering = false
        insights.track(categoryType, bufferingEventType, jumpKitPlayerIntervalContext(insights._playbackBufferingBenchmarkStop(), contextData, playbackSession, video))
      end if

      insights._playbackIntervalBenchmarkInit()

      if insights._tracking.reportedPlaybackStarted = invalid then

        insights._tracking.reportedPlaybackStarted = true

        eventType = constants.insights.events.player.playbackStarted
        eventContextInformation = jumpKitPlayerContext(contextData, playbackSession, video)
        insights.track(categoryType, eventType, eventContextInformation)
      end if
    else if state = "paused"
      insights._playbackBufferingBenchmarkStop()
      jumpKitSendPlaybackIntervalIfNeeded(categoryType, constants.insights.events.player.playbackInterval, insights._playbackIntervalBenchmarkStop(), contextData, playbackSession, video)
      insights.track(categoryType, constants.insights.events.player.playbackPaused, jumpKitPlayerContext(contextData, playbackSession, video))
    else if state = "error"
      insights.track(categoryType, constants.insights.events.player.playbackError, jumpKitPlayerContext(contextData, playbackSession, video))
      jumpKitSendPlaybackIntervalIfNeeded(categoryType, constants.insights.events.player.playbackInterval, insights._playbackIntervalBenchmarkStop(), contextData, playbackSession, video)
    else if state = "stopped"
      jumpKitSendPlaybackIntervalIfNeeded(categoryType, constants.insights.events.player.playbackInterval, insights._playbackIntervalBenchmarkStop(), contextData, playbackSession, video)
    else if state = "finished"
      jumpKitSendPlaybackIntervalIfNeeded(categoryType, constants.insights.events.player.playbackInterval, insights._playbackIntervalBenchmarkStop(), contextData, playbackSession, video)
      insights.track(categoryType, constants.insights.events.player.playbackEnded, jumpKitPlayerContext(contextData, playbackSession, video))
    end if
  end if
end sub

sub jumpKitSendPlaybackIntervalIfNeeded(categoryType, eventType, playbackInterval, contextData as object, playbackSession as string, video as object)
  if playbackInterval = 0
    return
  end if

  insights = JumpKitInstance().insights

  constants = JumpKitConstants()
  categoryType = constants.insights.categories.player

  event = jumpKitPlayerIntervalContext(playbackInterval, contextData, playbackSession, video)

  insights.track(categoryType, constants.insights.events.player.playbackInterval, event)
end sub

function jumpKitPlayerIntervalContext(interval as integer, contextData as object, playbackSession as string, video as object) as object

  contextData = {
    "playerInterval": interval
  }
  eventContextInfo = jumpKitPlayerContext(contextData, playbackSession, video)

  return eventContextInfo
end function

function jumpKitPlayerTimeshiftContext(timeshift as integer, contextData as object, playbackSession as string, video as object) as object

  contextData = {
    "timeshift": timeshift
  }
  eventContextInfo = jumpKitPlayerContext(contextData, playbackSession, video)

  return eventContextInfo
end function

function jumpKitPlayerContext(contextData as Dynamic, playbackSession as string, video as object) as object
  insights = JumpKitInstance().insights

  eventContextInfo = {
    "playerInfo": {
      "playbackSession": playbackSession
      "playerType": 0
      "currentTime": video.position
      "totalTime": video.duration
      "contentId": insights._contentInfo.contentId
      "content": insights._contentInfo
    }
  }

  if contextData <> invalid
    eventContextInfo.playerInfo.append({ "contextData": contextData })
  end if

  return eventContextInfo
end function
