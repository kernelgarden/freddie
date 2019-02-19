defmodule FreddieTest.Handler do
  use Freddie.Router

  require Logger

  alias FreddieTest.Scheme

  tcp Scheme.Echo do
    echo = Scheme.Echo.new(msg: msg.msg)
    Freddie.Session.send(socket, echo)
  end

  connect do
    Logger.info("Client #{inspect socket} is connected!")
  end

  disconnect do
    Logger.info("Client #{inspect socket} is disconnected!")
  end
end
