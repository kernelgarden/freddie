defmodule FreddieTest.Repo do
  use Ecto.Repo,
    otp_app: :freddie_test,
    adapter: Ecto.Adapters.MySQL
end
