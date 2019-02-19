defmodule FreddieTest.Handler do
  use Freddie.Router

  require Logger

  alias FreddieTest.Scheme

  handler Scheme.Echo do
    echo = Scheme.Echo.new(msg: msg.msg)
    case Freddie.Scheme.Common.new_message(echo) do
      resp ->
        Freddie.Session.send(socket, resp)
      {:error, reason} ->
        Logger.error("Failed to send, reason: #{reason}")
    end
  end
end
