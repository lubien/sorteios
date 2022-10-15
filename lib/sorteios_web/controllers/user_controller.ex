defmodule SorteiosWeb.UserController do
  use SorteiosWeb, :controller

  alias Sorteios.Accounts
  alias Sorteios.Accounts.User

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    user_params |> IO.inspect(label: "#{__MODULE__}:#{__ENV__.line} #{DateTime.utc_now}", limit: :infinity)
    conn
    |> put_session("name", user_params["name"])
    |> put_session("email", user_params["email"])
    |> redirect(to: Routes.room_index_path(conn, :index))
  end
end
