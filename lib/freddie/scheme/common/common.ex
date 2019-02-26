defmodule Freddie.Scheme.Common do
  use Protobuf,
    from: Path.wildcard(Path.expand("./definitions/**/*.proto", __DIR__)),
    use_package_names: true,
    namespace: "Elixir.Freddie.Scheme"

  alias Freddie.Utils
  alias Freddie.Scheme.Common.Message
  alias Freddie.Security

  @max_packet_size 65535

  def new_message(payload, aes_key, opts) do
    use_encryption =
      Keyword.get(opts, :use_encryption, false) and
        Keyword.get(opts, :is_established_encryption, false)

    # Todo: genderate id automatic
    cur_timestamp = DateTime.to_unix(DateTime.utc_now())
    protocol_mod = payload.__struct__
    command = Freddie.Router.lookup(protocol_mod)

    meta =
      Message.Meta.new(
        id: 0,
        command: command,
        timestamp: cur_timestamp,
        use_encryption: use_encryption
      )

    encoded_payload =
      case use_encryption do
        false ->
          protocol_mod.encode(payload)

        true ->
          Security.Aes.encrypt(aes_key, protocol_mod.encode(payload))
      end

    msg = Message.new(meta: meta, payload: encoded_payload)

    encoded = Message.encode(msg)
    size = byte_size(encoded)

    case size > @max_packet_size do
      false -> Utils.pack_message(encoded)
      true -> {:error, :flood_size}
    end
  end

  @doc """
  for dummy test...
  DO NOT USE THIS FUNCTION
  """
  def new_message_dummy(command, payload, aes_key, opts) do
    use_encryption = Keyword.get(opts, :use_encryption, false)

    cur_timestamp = DateTime.to_unix(DateTime.utc_now())
    protocol_mod = payload.__struct__

    meta = Message.Meta.new(id: 0, command: command, timestamp: cur_timestamp, use_encryption: use_encryption)

    encoded_payload =
      case use_encryption do
        false ->
          protocol_mod.encode(payload)

        true ->
          Security.Aes.encrypt(aes_key, protocol_mod.encode(payload))
      end

    msg = Message.new(meta: meta, payload: encoded_payload)
    encoded = Message.encode(msg)

    size = byte_size(encoded)

    case size > @max_packet_size do
      false -> Utils.pack_message(encoded)
      true -> {:error, :flood_size}
    end
  end

  # Todo: error handling...
  def decode_message(encoded_message, aes_key) do
    message = Message.decode(encoded_message)

    payload =
      case message.meta.use_encryption do
        false ->
          message.payload

        true ->
          Security.Aes.decrypt(aes_key, message.payload)
      end

    IO.puts("[Debug] decode_message: #{inspect message.meta.command}, #{inspect message.meta}, #{inspect payload}")

    {message.meta.command, message.meta, payload}
  end
end
