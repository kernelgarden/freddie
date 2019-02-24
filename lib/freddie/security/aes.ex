defmodule Freddie.Security.Aes do
  # http://erlang.org/doc/man/crypto.html#block_encrypt-4

  alias __MODULE__

  @cipher_mode :aes_gcm
  @aad "FREDDIE_AES256GCM"
  @iv_size 16
  @tag_size 16

  @spec generate_aes_key(any()) :: binary() | {:error, {:generate_aes_key, <<_::64, _::_*8>>}}
  def generate_aes_key(secret_key) when is_bitstring(secret_key) do
    :crypto.hash(:sha256, secret_key)
  end

  def generate_aes_key(secret_key) do
    {:error, {:generate_aes_key, "not valid type #{inspect(secret_key)}"}}
  end

  @spec encrypt(
          binary()
          | maybe_improper_list(
              binary() | maybe_improper_list(any(), binary() | []) | byte(),
              binary() | []
            ),
          binary()
          | maybe_improper_list(
              binary() | maybe_improper_list(any(), binary() | []) | byte(),
              binary() | []
            )
        ) :: binary()
  def encrypt(aes_key, value) do
    iv = :crypto.strong_rand_bytes(@iv_size)

    {cipher_text, cipher_tag} =
      :crypto.block_encrypt(@cipher_mode, aes_key, iv, {@aad, value, @tag_size})

    iv <> cipher_tag <> cipher_text
  end

  @spec decrypt(
          binary()
          | maybe_improper_list(
              binary() | maybe_improper_list(any(), binary() | []) | byte(),
              binary() | []
            ),
          <<_::64, _::_*8>>
        ) :: :error | binary()
  def decrypt(aes_key, cipher_block) do
    <<iv::binary-@iv_size, cipher_tag::binary-@tag_size, cipher_text::binary>> = cipher_block
    :crypto.block_decrypt(@cipher_mode, aes_key, iv, {@aad, cipher_text, cipher_tag})
  end

  def test() do
    client_private_key =
      Freddie.Security.DiffieHellman.generate_private_key()
      |> IO.inspect(label: "[Debug] client_private_key: ")

    server_private_key =
      Freddie.Security.DiffieHellman.generate_private_key()
      |> IO.inspect(label: "[Debug] server_private_key: ")

    client_public_key =
      Freddie.Security.DiffieHellman.generate_public_key(client_private_key)
      |> IO.inspect(label: "[Debug] client_public_key: ")

    server_public_key =
      Freddie.Security.DiffieHellman.generate_public_key(server_private_key)
      |> IO.inspect(label: "[Debug] server_public_key: ")

    client_secret_key =
      Freddie.Security.DiffieHellman.generate_secret_key(server_public_key, client_private_key)
      |> IO.inspect(label: "[Debug] client_secret_key: ")

    server_secret_key =
      Freddie.Security.DiffieHellman.generate_secret_key(client_public_key, server_private_key)
      |> IO.inspect(label: "[Debug] server_secret_key: ")

    key =
      server_secret_key
      |> IO.inspect(label: "[Debug] key: ")

    aes_key =
      Aes.generate_aes_key(key)
      |> IO.inspect(label: "[Debug] aes_key: ")

    plain_text = "plain text.plain text.plain text.plain text."

    cipher_block =
      Aes.encrypt(aes_key, plain_text)
      |> IO.inspect(label: "[Debug] cipher_block: ")

    decrypt_text =
      Aes.decrypt(aes_key, cipher_block)
      |> IO.inspect(label: "[Debug] decrypt_text: ")
  end
end
