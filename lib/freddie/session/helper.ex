defmodule Freddie.Session.Helper do

  # http://blog.yufeng.info/archives/2970#more-2970
  def activate_socket(socket) do
    :inet.setopts(socket, active: 30)
  end
end
