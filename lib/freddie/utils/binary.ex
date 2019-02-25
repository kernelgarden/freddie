defmodule Freddie.Utils.Binary do

  def to_big_integer(integer) when is_integer(integer) do
    :binary.encode_unsigned(integer)
  end

  def to_big_integer(integer) when is_binary(integer) do
    integer
  end

  def from_big_integer(big_integer) do
    :binary.decode_unsigned(big_integer)
  end
end
