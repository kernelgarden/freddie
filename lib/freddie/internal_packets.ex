defmodule Freddie.InternalPackets do
  use EnumType

  defenum Types do
    value(Freddie.Scheme.Common.ConnectionInfo, -1)
    value(Freddie.Scheme.Common.ConnectionInfoReply, -2)
  end
end
