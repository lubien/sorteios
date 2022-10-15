defmodule SorteiosWeb.UserController do
  use SorteiosWeb, :controller

  alias Sorteios.Rooms
  alias Sorteios.Accounts
  alias Sorteios.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  # Quer entrar em uma sala
  def create(conn, %{"user" => %{"room_id" => room_id} = user_params}) when room_id not in [""] do
    room = Rooms.get_room!(room_id)

    conn
    |> put_session("name", user_params["name"])
    |> put_session("email", user_params["email"])
    |> delete_session("admin")
    |> redirect(to: Routes.room_show_path(conn, :show, room.id))
  end

  # Quer criar uma sala
  def create(conn, %{"user" => user_params}) do
    {:ok, room} = Rooms.create_room(%{})

    conn
    |> put_session("name", user_params["name"])
    |> put_session("email", user_params["email"])
    |> put_session("admin", room.id)
    |> redirect(to: Routes.room_show_path(conn, :show, room.id))
  end
end
