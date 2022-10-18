defmodule SorteiosWeb.SessionController do
  use SorteiosWeb, :controller

  alias Sorteios.Rooms
  alias Sorteios.Accounts
  alias Sorteios.Accounts.User

  def new(conn, params) do
    changeset =
      Accounts.change_user(%User{
        name: get_session(conn, "name"),
        email: get_session(conn, "email"),
        room_id: params["room_id"]
      })

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"action" => "join_room", "user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    if room = Rooms.get_room(user_params["room_id"]) do
      case changeset do
        %Ecto.Changeset{valid?: true} ->
          join_room(conn, room, user_params, false)

        changeset ->
          changeset = Map.put(changeset, :action, :save)
          render(conn, "new.html", changeset: changeset)
      end
    else
      changeset =
        changeset
        |> Ecto.Changeset.add_error(:room_id, "Room not found")
        |> Map.put(:action, :save)

      render(conn, "new.html", changeset: changeset)
    end
  end

  def create(conn, %{"user" => user_params}) do
    case User.changeset(%User{}, user_params) do
      %Ecto.Changeset{valid?: true} ->
        {:ok, room} = Rooms.create_room(%{})
        join_room(conn, room, user_params, true)

      changeset ->
        changeset = Map.put(changeset, :action, :save)
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, _) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  defp join_room(conn, room, params, admin?) do
    key = "admin:#{room.id}"

    conn =
      if admin? do
        put_session(conn, key, room.id)
      else
        delete_session(conn, key)
      end

    conn
    |> put_session("name", params["name"])
    |> put_session("email", params["email"])
    |> redirect(to: Routes.room_show_path(conn, :show, room.id))
  end
end
