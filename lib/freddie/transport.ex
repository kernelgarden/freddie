defmodule Freddie.Transport do

  require Logger

  @spec port_cmd(port(), iodata()) :: any()
  def port_cmd(socket, data) when socket != nil and is_port(socket) do
    try do
      case :erlang.port_command(socket, data, [:nosuspend]) do
        false ->
          # Todo: prepend to send buffer
          :port_is_busy
        true -> :ok
      end
    rescue
      #e in ArgumentError ->
        #Logger.error("port_cmd error! #{inspect socket} - #{is_port(socket) or is_atom(socket)}, #{inspect data} - #{is_binary(data)}, #{inspect e}")
      #  e
      error ->
        error
    end
  end
end
