sub init()
  m.port = createObject("roMessagePort")
  m.top.functionName = "jumpKitRunLoop"
  m.top.control = "RUN"

  m.jumpKit = JumpKit()
end sub

sub jumpKitRunLoop()
  secondsToWait = 5 * 1000
  
  while true
    msg = wait(secondsToWait, m.port)

    m.jumpkit._internal.sync()
  end while
end sub