defmodule SorteiosWeb.RoomLive.Show do
  use SorteiosWeb, :live_view

  alias Phoenix.PubSub
  alias Sorteios.Rooms
  alias Sorteios.Rooms.Prize
  alias SorteiosWeb.Presence

  @impl true
  def mount(%{"id" => id}, session, socket) do
    topic = "room:#{id}"

    PubSub.subscribe(Sorteios.PubSub, topic)

    Presence.track(
      self(),
      topic,
      session["email"],
      %{
        name: session["name"],
        email: session["email"]
      }
    )

    SorteiosWeb.Endpoint.subscribe(topic)


    {:ok,
      socket
      |> assign(:admin?, session["admin"] == id)
      |> assign(:id, id)
      |> assign(:users, [])
      |> assign(:prizes, [])
      |> assign(:changeset, Rooms.change_prize(%Prize{}))
      |> reload_users()
      |> reload_prizes()
    }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Rooms.get_room!(id))}
  end

  @impl true
  def handle_event("create_prize", %{"prize" => prize_params}, socket) do
    prize_params = Map.put(prize_params, "room_id", socket.assigns.id)

    case Rooms.create_prize(prize_params) do
      {:ok, _prize} ->
        PubSub.broadcast(Sorteios.PubSub, topic(socket), "reload_prizes")

        {:noreply,
         socket
         |> reload_prizes()
         |> put_flash(:info, "Prize created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, reload_users(socket)}
  end
  def handle_info("reload_prizes", socket) do
    {:noreply, reload_prizes(socket)}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp topic(socket), do: "room:#{socket.assigns.id}"

  def reload_prizes(socket) do
    socket
    |> assign(:prizes, Rooms.list_prizes(socket.assigns.id))
  end

  def reload_users(socket) do
    users =
      Presence.list(topic(socket))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)

    socket
    |> assign(:users, users)
  end
end
