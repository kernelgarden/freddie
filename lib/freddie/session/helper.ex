defmodule Freddie.Session.Helper do
  def activate_socket(socket) do
    :inet.setopts(socket, active: 30)
  end
end
