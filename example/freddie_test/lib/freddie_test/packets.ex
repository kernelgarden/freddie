defmodule FreddieTest.Packets do
  use EnumType

  defenum Types do
    value FreddieTest.Scheme.CS_Echo, 1
    value FreddieTest.Scheme.SC_Echo, 2
  end
end
