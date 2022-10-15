defmodule SorteiosWeb.RoomLive.Show do
  use SorteiosWeb, :live_view

  alias Sorteios.Rooms
  alias SorteiosWeb.Presence

  @impl true
  def mount(%{"id" => id}, session, socket) do
    topic = "room:#{id}"

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
      |> reload_users()
    }
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Rooms.get_room!(id))}
  end

  def handle_info(%{event: "presence_diff"} = event, socket) do
    {:noreply, reload_users(socket)}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp topic(socket), do: "room:#{socket.assigns.id}"

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
