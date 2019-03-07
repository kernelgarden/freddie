defmodule Freddie.Session.Helper do
  @moduledoc false

  # http://blog.yufeng.info/archives/2970#more-2970
  @spec activate_socket(port()) :: :ok | {:error, atom()}
  def activate_socket(socket) do
    :inet.setopts(socket, active: 30)
  end
end
