defmodule FreddieTest.Handler.Login do

  def handle({context, msg}) do
    req_id = msg.id

    user =
      FreddieTest.Model.User
      |> FreddieTest.Repo.get(req_id)

    response =
      case user do
        nil ->
          # Todo: add fail process
          :noop
        user ->
          position = FreddieTest.Scheme.Position.new(x: user.current_pos_x, y: user.current_pos_y, z: user.current_pos_z)
          FreddieTest.Scheme.SC_Login.new(id: user.id, player_name: user.player_name, player_pos: position)
      end

    Freddie.Session.send(context, response)
  end

end
