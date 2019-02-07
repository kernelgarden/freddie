defmodule FreddieTest.Handler do
  alias FreddieTest.Scheme

  def handle({command, meta, payload}, socket) do
    route_by_protocol(command, meta, payload, socket)
  end

  defp route_by_protocol(command, _meta, payload, socket) do
    case command do
      1 ->
        echo = Scheme.Echo.decode(payload)
        # IO.puts("Received from client: #{inspect echo.msg}")
        {:ok, resp} = Freddie.Scheme.Common.new_message(1, payload)
        Freddie.Transport.port_cmd(socket, resp)

      _ ->
        :error
    end
  end
end
