defmodule Freddie.Security.Aes do
  # http://erlang.org/doc/man/crypto.html#block_encrypt-4

  alias __MODULE__

  @cipher_mode :aes_gcm
  @aad "AES256GCM"
  @iv_size 16
  @tag_size 16

  def generate_aes_key(secret_key) when is_bitstring(secret_key) do
    aes_key = :crypto.hash(:sha256, secret_key)
  end

  def generate_aes_key(secret_key) do
    {:error, {:generate_aes_key, "not valid type #{inspect secret_key}"}}
  end

  def encrypt(aes_key, value) do
    iv = :crypto.strong_rand_bytes(@iv_size)
    {cipher_text, cipher_tag} = :crypto.block_encrypt(@cipher_mode, aes_key, iv, {@aad, value, @tag_size})
    iv <> cipher_tag <> cipher_text
  end

  def decrypt(aes_key, cipher_block) do
    <<iv::binary-@iv_size, cipher_tag::binary-@tag_size, cipher_text::binary>> = cipher_block
    :crypto.block_decrypt(@cipher_mode, aes_key, iv, {@aad, cipher_text, cipher_tag})
  end

  def test() do
    key = :crypto.strong_rand_bytes(32)
    |> IO.inspect(label: "[Debug] key: ")

    aes_key = Aes.generate_aes_key(key)
    |> IO.inspect(label: "[Debug] aes_key: ")

    plain_text = "plain text.plain text.plain text.plain text."

    cipher_block = Aes.encrypt(aes_key, plain_text)
    |> IO.inspect(label: "[Debug] cipher_block: ")

    decrypt_text = Aes.decrypt(aes_key, cipher_block)
    |> IO.inspect(label: "[Debug] decrypt_text: ")
  end
end
