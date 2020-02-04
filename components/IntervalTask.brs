sub init()
  m.port = createObject("roMessagePort")
  m.top.functionName = "intervalRunLoop"
  m.top.control = "RUN"

  m.jumpKit = JumpKit()
end sub

sub intervalRunLoop()
  constants = JumpKitConstants()

  secondsToWait = 60 * 1000
  
  categoryType = constants.insights.categories.player
  eventType = constants.insights.events.player.playbackInterval
  contextData = invalid
  eventContextInformation = m.top.eventContextInformation
  playbackSession = m.top.playbackSession
  videoPlayer = m.top.videoPlayer

  while true

    msg = wait(secondsToWait, m.port)

    if not m.top.isPaused then
      intervalTaskSendPlaybackIntervalIfNeeded(categoryType, eventType, taskIntervalStop(m.top.startTime), contextData, eventContextInformation, playbackSession, videoPlayer)

      m.top.startTime = 0 'notify the listener to re init playbackStart time
    end if
  end while
end sub