defmodule Freddie.Scheme.Common do
  use Protobuf, """
  syntax = "proto3";
  package Common;

  message Message{
    message Meta {
        int32 id = 1;
        int32 command = 4;
        int32 timestamp = 5;
    }

    Meta meta = 1;
    string payload = 2;
  }
  """

  alias Freddie.Utils
  alias Freddie.Scheme.Common.Message

  @max_packet_size 65535

  def new_message(command, payload) do
    # Todo: genderate id automatic
    cur_timestamp = DateTime.to_unix(DateTime.utc_now())
    meta = Message.Meta.new(id: 0, command: command, timestamp: cur_timestamp)
    msg = Message.new(meta: meta, payload: payload)
    encoded = Message.encode(msg)

    size = byte_size(encoded)

    case size > @max_packet_size do
      false -> {:ok, Utils.pack_message(encoded)}
      true -> {:error, :flood_size}
    end
  end

  # Todo: error handling...
  def decode_message(encoded_message) do
    message = Message.decode(encoded_message)
    {message.meta.command, message.meta, message.payload}
  end
end
