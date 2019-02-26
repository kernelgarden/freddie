defmodule FreddieTest.Packets do
  use EnumType

  defenum Types do
    value(FreddieTest.Scheme.CS_Echo, 1)
    value(FreddieTest.Scheme.SC_Echo, 2)
    value(FreddieTest.Scheme.CS_EncryptPing, 3)
    value(FreddieTest.Scheme.SC_EncryptPong, 4)
  end
end
