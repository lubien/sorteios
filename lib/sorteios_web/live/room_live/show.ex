defmodule SorteiosWeb.RoomLive.Show do
  use SorteiosWeb, :live_view

  alias Sorteios.Rooms
  alias SorteiosWeb.Presence

  @impl true
  def mount(%{"id" => id}, session, socket) do
    session |> IO.inspect(label: "#{__MODULE__}:#{__ENV__.line} #{DateTime.utc_now}", limit: :infinity)
    topic = "room:#{id}"
    user_id = 1

    Presence.track(
      self(),
      topic,
      user_id,
      %{
        name: "lubien",
        # email: current_user.email,
        user_id: user_id
      }
    )

    SorteiosWeb.Endpoint.subscribe(topic)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Rooms.get_room!(id))}
  end

  def handle_info(%{event: "presence_diff"} = event, socket) do
    event |> IO.inspect(label: "#{__MODULE__}:#{__ENV__.line} #{DateTime.utc_now}", limit: :infinity)
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
