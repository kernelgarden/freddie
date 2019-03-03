defmodule FreddieTest.Packets do
  use EnumType

  defenum Types do
    # echo
    value(FreddieTest.Scheme.CS_Echo, 1)
    value(FreddieTest.Scheme.SC_Echo, 2)

    # encryption test
    value(FreddieTest.Scheme.CS_EncryptPing, 3)
    value(FreddieTest.Scheme.SC_EncryptPong, 4)

    # login
    value(FreddieTest.Scheme.CS_Login, 5)
    value(FreddieTest.Scheme.SC_Login, 6)
  end
end
