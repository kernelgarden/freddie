defmodule Freddie.Scheme.Common.Connection do
  alias Freddie.Security.DiffieHellman

  def make_connection_info() do
    sever_private_key = DiffieHellman.generate_private_key()
  end
end
