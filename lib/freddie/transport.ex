defmodule Freddie.Transport do

  @spec port_cmd(any(), any()) :: any()
  def port_cmd(socket, data) when socket != nil do
    try do
      case :erlang.port_command(socket, data, [:nosuspend]) do
        false ->
          # Todo: prepend to send buffer
          nil
        true -> true
      end
    catch
      error ->
        error
    end
  end
end