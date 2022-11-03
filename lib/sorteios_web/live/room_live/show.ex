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
       |> assign(:region, System.get_env("FLY_REGION") || "iad")
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

  def handle_event("remove_prize", %{"prize-name" => prize_name}, socket) do
    prize =
      socket.assigns.available_prizes
      |> Enum.filter(&(&1.name == prize_name))
      |> List.first()

    case Rooms.delete_prize(prize) do
      {:ok, _prize} ->
        PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

        {:noreply,
         socket
         |> reload_prizes()
         |> put_flash(:info, "Prize removed successfully")}

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

  def handle_event("ping", %{"rtt" => rtt}, socket) do
    {:noreply, push_event(socket, "pong", %{rtt: rtt})}
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

  def compute_chance(users_length) do
    if users_length > 0 do
      100/users_length
    else
      0.0
    end
  end

  def reload_users(socket) do
    users =
      Presence.list(topic(socket))
      |> Enum.map(fn {_user_id, data} ->
        data[:metas]
        |> List.first()
      end)
      |> Enum.dedup_by(& &1[:email])

    eligible_users_count = length(users) - 1
    winning_chance = compute_chance(eligible_users_count)

    socket
    |> assign(:users, users)
    |> assign(:eligible_users_count, eligible_users_count)
    |> assign(:winning_chance, winning_chance)
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
    ~H"""
    <div class="relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400">
      <div class="flex-shrink-0">
        <img class="h-10 w-10 rounded-full" src={gravatar(@user.email)} alt="" />
      </div>
      <div class="min-w-0 flex-1">
        <a href="#" class="focus:outline-none">
          <span class="absolute inset-0" aria-hidden="true"></span>
          <p class="text-sm font-medium text-gray-900"><%= @user.name %></p>
          <%= if @show_email? do %>
            <p class="truncate text-sm text-gray-500"><%= @user.email %></p>
          <% end %>
        </a>
      </div>
    </div>
    """
  end
end
