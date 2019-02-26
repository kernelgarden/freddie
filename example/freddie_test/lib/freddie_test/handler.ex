defmodule FreddieTest.Handler do
  use Freddie.Router

  require Logger

  alias FreddieTest.Scheme

  defhandler Scheme.CS_Echo do
    echo = Scheme.SC_Echo.new(msg: msg.msg)
    Freddie.Session.send(context, echo)
  end

  connect do
    Logger.info("Client #{inspect(context)} is connected!")
  end

  disconnect do
    Logger.info("Client #{inspect(context)} is disconnected!")
  end

  default do
  end
end
