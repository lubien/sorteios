defmodule SorteiosWeb.RoomLive.Index do
  use SorteiosWeb, :live_view

  alias Sorteios.Rooms
  alias Sorteios.Rooms.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :rooms, list_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Rooms.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Rooms.get_room!(id)
    {:ok, _} = Rooms.delete_room(room)

    {:noreply, assign(socket, :rooms, list_rooms())}
  end

  def handle_event("create_room", _params, socket) do
    case Rooms.create_room(%{}) do
      {:ok, room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room created successfully")
         |> push_redirect(to: Routes.room_show_path(socket, :show, room.id))}

      # {:error, %Ecto.Changeset{} = changeset} ->
      #   {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp list_rooms do
    Rooms.list_rooms()
  end
end
