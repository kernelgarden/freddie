defmodule Freddie.Session.PacketHandler do
  @moduledoc false

  # header size is unsigned integer of 2 byte
  @header_unit 2
  @header_size @header_unit * 8

  @spec on_read(Freddie.Context.t()) :: Freddie.Context.t()
  def on_read(%Freddie.Context{session: %Freddie.Session{} = session} = context) do
    new_session =
      case parse(session.buffer, context) do
        :empty ->
          %Freddie.Session{session | buffer: <<>>}

        {:not_enough_data, remain} ->
          %Freddie.Session{session | buffer: remain}
      end

    Freddie.Context.set_session(context, new_session)
  end

  defp parse(<<>>, _session) do
    :empty
  end

  # To maximize optimization, I adopt like this.
  # http://erlang.org/doc/efficiency_guide/binaryhandling.html#matching-binaries
  defp parse(<<length::big-@header_size, data::binary>> = buffer, context) do
    # not good use unknown-length matches on sub-binaries, so i calculate first!
    rest_len = byte_size(buffer) - (@header_unit + length)
    case data do
      <<cur_data::binary-size(length), remain::binary-size(rest_len)>> ->
        session = Freddie.Context.get_session(context)

        session.packet_handler_mod.dispatch(
          Freddie.Scheme.Common.decode_message(cur_data, session.secret_key),
          context
        )

        parse(remain, context)

      _ ->
        {:not_enough_data, buffer}
    end
  end

  defp parse(<<buffer::binary>>, _context) when is_binary(buffer) do
    {:not_enough_data, buffer}
  end
end
