defmodule Freddie.Scheme.Common do
  use Protobuf, from: Path.wildcard(Path.expand("./definitions/**/*.proto", __DIR__)), use_package_names: true, namespace: "Elixir.Freddie.Scheme"

  alias Freddie.Utils
  alias Freddie.Scheme.Common.Message

  @max_packet_size 65535

  def new_message(payload) do
    # Todo: genderate id automatic
    cur_timestamp = DateTime.to_unix(DateTime.utc_now())
    protocol_mod = payload.__struct__
    command = Freddie.Router.lookup(protocol_mod)

    meta = Message.Meta.new(id: 0, command: command, timestamp: cur_timestamp)
    msg = Message.new(meta: meta, payload: protocol_mod.encode(payload))
    encoded = Message.encode(msg)

    size = byte_size(encoded)

    case size > @max_packet_size do
      false -> Utils.pack_message(encoded)
      true -> {:error, :flood_size}
    end
  end

  # for dummy test...
  # DO NOT USE THIS FUNCTION
  def new_message(command, payload) do
    cur_timestamp = DateTime.to_unix(DateTime.utc_now())
    protocol_mod = payload.__struct__

    meta = Message.Meta.new(id: 0, command: command, timestamp: cur_timestamp)
    msg = Message.new(meta: meta, payload: protocol_mod.encode(payload))
    encoded = Message.encode(msg)

    size = byte_size(encoded)

    case size > @max_packet_size do
      false -> Utils.pack_message(encoded)
      true -> {:error, :flood_size}
    end
  end

  # Todo: error handling...
  def decode_message(encoded_message) do
    message = Message.decode(encoded_message)
    {message.meta.command, message.meta, message.payload}
  end
end
