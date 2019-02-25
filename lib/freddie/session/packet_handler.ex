defmodule Freddie.Session.PacketHandler do
  # header size is unsigned integer of 2 byte
  @header_size 2 * 8

  @spec onRead(Freddie.Context.t()) :: Freddie.Context.t()
  def onRead(%Freddie.Context{session: %Freddie.Session{} = session} = context) do
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
    case data do
      <<cur_data::binary-size(length), remain::binary>> ->
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

  defp parse(buffer, _context) do
    {:not_enough_data, buffer}
  end
end
