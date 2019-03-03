defmodule FreddieTest.Model.User do
  use Ecto.Schema

  schema "user" do
    field :player_name, :string
    field :current_pos_x, :float
    field :current_pos_y, :float
    field :current_pos_z, :float
    field :create_time, :utc_datetime
    field :is_valid, :boolean
  end

end
