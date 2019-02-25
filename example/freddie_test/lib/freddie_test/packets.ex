defmodule FreddieTest.Packets do
  use EnumType

  alias FreddieTest.Scheme

  defenum Types do
    #value CS_Echo, 1
    #value SC_Echo, 2
    value CS_Echo, {1, Scheme.CS_Echo}
    value SC_Echo, {2, Scheme.SC_Echo}
  end

end
