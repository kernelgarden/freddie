defmodule Freddie.Session.Helper do
  def activate_socket(socket) do
    :inet.setopts(socket, [active: :once])
  end

  def pack_packet(header, payload) do

  end
end
