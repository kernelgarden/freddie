defmodule Freddie.Session.PacketHandler do
  # header size is unsigned integer of 2 byte
  @header_size 2 * 8

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

  defp parse(<<length::big-@header_size, data::binary>>, session) do
    case data do
      <<cur_data::binary-size(length), remain::binary>> ->
        session.packet_handler_mod.handle(
          Freddie.Scheme.Common.decode_message(cur_data),
          session.socket
        )

        parse(remain, session)

      _ ->
        {:not_enough_data, data}
    end
  end
end
