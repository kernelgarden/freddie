defmodule Freddie.ByteBuffer do
  @moduledoc """
  Circular buffer for packets.
  """

  defstruct buf: <<>>

  def new(data \\ <<>>) do
    %Freddie.ByteBuffer{buf: data}
  end

  def peek(%Freddie.ByteBuffer{buf: buf} = _buffer, size) when byte_size(buf) >= size do
    <<data :: binary - size(size), _remain :: binary>> = buf
    data
  end

  def peek(_buffer, _size) do
    {:error, :exceed_current_size}
  end

  def pop(%Freddie.ByteBuffer{buf: buf} = _buffer, size) when byte_size(buf) >= size do
    <<data :: binary - size(size), remain :: binary>> = buf
    {data, Freddie.ByteBuffer.new(remain)}
  end

  def pop(_buffer, _size) do
    {:error, :exceed_current_size}
  end

  def push(buffer, data) do
    Freddie.ByteBuffer.new(buffer.buf <> data)
  end
end
