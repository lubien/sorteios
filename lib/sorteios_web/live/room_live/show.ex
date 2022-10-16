defmodule SorteiosWeb.RoomLive.Show do
  use SorteiosWeb, :live_view

  alias Phoenix.PubSub
  alias Sorteios.Rooms
  alias Sorteios.Rooms.Room
  alias Sorteios.Rooms.Prize
  alias SorteiosWeb.Presence

  @impl true
  def mount(%{"id" => id}, %{"name" => name, "email" => email} = session, socket) do
    if room = Rooms.get_room(id) do
      current_user = %{
        name: name,
        email: email
      }

      PubSub.subscribe(Sorteios.PubSub, topic(room))
      {:ok, _} = Presence.track(self(), topic(room), email, current_user)

      SorteiosWeb.Endpoint.subscribe(topic(room))

      invite_image =
        Routes.room_show_url(socket, :show, id)
        |> EQRCode.encode()
        |> EQRCode.svg(width: 240)

      {:ok,
       socket
       |> assign(:page_title, "Room #{id}")
       |> assign(:admin?, session["admin:#{id}"] == id)
       |> assign(:id, id)
       |> assign(:room, room)
       |> assign(:current_user, current_user)
       |> assign(:users, [])
       |> assign(:prizes, [])
       |> assign(:invite_image, invite_image)
       |> assign(:random_person, nil)
       |> assign(:changeset, Rooms.change_prize(%Prize{}))
       |> reload_users()
       |> reload_prizes()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Room not found")
       |> redirect(to: Routes.session_path(socket, :new))}
    end
  end

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> put_flash(:info, "You need to specify your name and email to enter")
     |> redirect(to: Routes.session_path(socket, :new, room_id: id))}
  end

  @impl true
  def handle_event("create_prize", %{"prize" => prize_params}, socket) do
    prize_params = Map.put(prize_params, "room_id", socket.assigns.id)

    case Rooms.create_prize(prize_params) do
      {:ok, _prize} ->
        PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

        {:noreply,
         socket
         |> reload_prizes()
         |> put_flash(:info, "Prize created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("pick_a_random_person", _params, socket) do
    random_person =
      socket.assigns.users
      |> Enum.reject(&(&1.email == socket.assigns.current_user.email))
      |> Enum.random()

    {:noreply,
     socket
     |> assign(:random_person, random_person)}
  end

  def handle_event("give_prize_to_random_person", _params, socket) do
    available_prizes = socket.assigns.available_prizes

    if Enum.any?(available_prizes) do
      {:noreply, award_prize(socket, List.first(available_prizes))}
    else
      {:noreply, put_flash(socket, :error, "Sem premios para sortear")}
    end
  end

  def handle_event("kick_person", %{"user-email" => user_email}, socket) do
    PubSub.broadcast!(Sorteios.PubSub, topic(socket), %{
      event: "kick",
      email: user_email
    })
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, reload_users(socket)}
  end

  def handle_info(%{event: "winner", winner: winner, prize: prize}, socket) do
    socket =
      socket
      |> reload_prizes()
      |> put_flash(:success, "#{winner.name} ganhou #{prize.name}")

    {:noreply, socket}
  end

  def handle_info("reload_prizes", socket) do
    {:noreply, reload_prizes(socket)}
  end

  def handle_info(%{event: "kick", email: email}, socket) do
    if (socket.assigns.current_user.email == email) do
      socket =
        socket
        |> put_flash(:error, "You were kicked out of the room.")
        |> redirect(to: Routes.session_path(socket, :new))
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp topic(%{assigns: %{room: room}}), do: topic(room)
  defp topic(%Room{id: id}), do: "room:#{id}"

  def award_prize(socket, prize) do
    winner = socket.assigns.random_person

    attrs = %{
      winner_name: winner.name,
      winner_email: winner.email
    }

    case Rooms.update_prize(prize, attrs) do
      {:ok, prize} ->
        PubSub.broadcast!(Sorteios.PubSub, topic(socket), %{
          event: "winner",
          winner: winner,
          prize: prize
        })

        socket
        |> assign(:random_person, nil)

        # todo: tratar o erro
    end
  end

  def reload_prizes(socket) do
    socket
    |> assign(:prizes, Rooms.list_prizes(socket.assigns.id))
    |> filter_available_prizes()
  end

  def reload_users(socket) do
    users =
      Presence.list(topic(socket))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)
      |> Enum.dedup_by(& &1[:email])

    socket
    |> assign(:users, users)
  end

  def filter_available_prizes(socket) do
    prizes = socket.assigns.prizes

    socket
    |> assign(:available_prizes, Enum.filter(prizes, &(&1.winner_name == nil)))
  end

  def gravatar(email) do
    hash =
      email
      |> String.trim()
      |> String.downcase()
      |> :erlang.md5()
      |> Base.encode16(case: :lower)

    "https://www.gravatar.com/avatar/#{hash}?s=150&d=identicon"
  end

  def user_block(assigns) do
    can_kick? = Map.get(assigns, :can_kick?, false)

    ~H"""
    <div class="relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400">
      <div class="flex-shrink-0">
        <img class="h-10 w-10 rounded-full" src={gravatar(@user.email)} alt="" />
      </div>
      <div class="min-w-0 flex-1">
        <p class="text-sm font-medium text-gray-900"><%= @user.name %></p>
        <%= if @show_email? do %>
          <p class="truncate text-sm text-gray-500"><%= @user.email %></p>
        <% end %>
      </div>
      <%= if can_kick? do %>
        <div class="flex-shrink-0">
          <button
            phx-click="kick_person"
            phx-value-user-email={@user.email}
            data-confirm="Are you sure? This cannot be undone"
            class="block w-full items-center justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:my-2 sm:w-auto sm:text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
      <% end %>
    </div>
    """
  end
end
