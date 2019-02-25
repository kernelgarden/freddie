defmodule Freddie.Security.DiffieHellman do
  # https://tools.ietf.org/html/rfc2409#page-21
  @oakley_group_2 179_769_313_486_231_590_770_839_156_793_787_453_197_860_296_048_756_011_706_444_423_684_197_180_216_158_519_368_947_833_795_864_925_541_502_180_565_485_980_503_646_440_548_199_239_100_050_792_877_003_355_816_639_229_553_136_239_076_508_735_759_914_822_574_862_575_007_425_302_077_447_712_589_550_957_937_778_424_442_426_617_334_727_629_299_387_668_709_205_606_050_270_810_842_907_692_932_019_128_194_467_627_007
  @base_number 2
  @private_key_size 160

  @spec generate_secret_key(binary() | integer(), binary() | integer()) :: :error | binary()
  def generate_secret_key(client_public_key, server_private_key) do
    :crypto.mod_pow(client_public_key, server_private_key, @oakley_group_2)
  end

  @spec generate_public_key(binary() | integer()) :: :error | binary()
  def generate_public_key(server_private_key) do
    :crypto.mod_pow(@base_number, server_private_key, @oakley_group_2)
  end

  @spec generate_private_key() :: non_neg_integer()
  def generate_private_key() do
    :binary.decode_unsigned(:crypto.strong_rand_bytes(@private_key_size))
  end

  def get_generator() do
    @base_number
  end

  def get_prime() do
    @oakley_group_2
  end
end
