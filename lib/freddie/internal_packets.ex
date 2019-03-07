defmodule Freddie.InternalPackets do
  @moduledoc false

  use EnumType

  defenum Types do
    @moduledoc false
    value(Freddie.Scheme.Common.ConnectionInfo, -1, do: @moduledoc false)
    value(Freddie.Scheme.Common.ConnectionInfoReply, -2, do: @moduledoc false)
  end
end
