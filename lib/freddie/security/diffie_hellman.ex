defmodule Freddie.Security.DiffieHellman do

  # https://tools.ietf.org/html/rfc2409#page-21
  @oakley_group_2 179769313486231590770839156793787453197860296048756011706444423684197180216158519368947833795864925541502180565485980503646440548199239100050792877003355816639229553136239076508735759914822574862575007425302077447712589550957937778424442426617334727629299387668709205606050270810842907692932019128194467627007
  @base_number 2

  def generate_secret_key(client_public_key, server_private_key) do
    #:binary.decode_unsigned(:crypto.mod_pow(client_public_key, server_private_key, @oakley_group_2))
    :crypto.mod_pow(client_public_key, server_private_key, @oakley_group_2)
  end

  def generate_public_key(server_private_key) do
    #:binary.decode_unsigned(:crypto.mod_pow(@base_number, server_private_key, @oakley_group_2))
    :crypto.mod_pow(@base_number, server_private_key, @oakley_group_2)
  end

  # use 20 of bits length integer
  def generate_private_key() do
    Enum.random(144115188075855872..1152921504606846975)
  end
end
