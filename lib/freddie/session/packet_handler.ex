defmodule Freddie.Session.PacketHandler do
  # header size is unsigned integer of 2 byte
  @header_size 2 * 8

  @spec onRead(Freddie.Session.t()) :: Freddie.Session.t()
  def onRead(%Freddie.Session{} = session) do
    new_session =
      case parse(session.buffer, session) do
        :empty ->
          %Freddie.Session{session | buffer: <<>>}

        {:not_enough_data, remain} ->
          %Freddie.Session{session | buffer: remain}
      end

    new_session
  end

  defp parse(<<>>, _session) do
    :empty
  end

  # To maximize optimization, I adopt like this.
  # http://erlang.org/doc/efficiency_guide/binaryhandling.html#matching-binaries
  defp parse(<<length::big-@header_size, data::binary>> = buffer, session) do
    case data do
      <<cur_data::binary-size(length), remain::binary>> ->
        session.packet_handler_mod.dispatch(
          Freddie.Scheme.Common.decode_message(cur_data),
          session.socket
        )

        parse(remain, session)

      _ ->
        {:not_enough_data, buffer}
    end
  end

  defp parse(buffer, _session) do
    {:not_enough_data, buffer}
  end
end
