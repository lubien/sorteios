defmodule SorteiosWeb.UserController do
  use SorteiosWeb, :controller

  alias Sorteios.Rooms
  alias Sorteios.Accounts
  alias Sorteios.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"action" => "join_room", "user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    room =
      try do
        Rooms.get_room(user_params["room_id"])
      rescue
        Ecto.Query.CastError ->
          nil
      end

    if room do
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

  defp join_room(conn, room, params, admin?) do
    conn =
      if admin? do
        put_session(conn, "admin", room.id)
      else
        delete_session(conn, "admin")
      end

    conn
    |> put_session("name", params["name"])
    |> put_session("email", params["email"])
    |> redirect(to: Routes.room_show_path(conn, :show, room.id))
  end
end
