defmodule FreddieTest.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :player_name, :string
      add :current_pos_x, :float
      add :current_pos_y, :float
      add :current_pos_z, :float
      add :create_time, :utc_datetime
      add :is_valid, :boolean
    end
  end
end
