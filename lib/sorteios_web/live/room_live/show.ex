defmodule SorteiosWeb.RoomLive.Show do
  use SorteiosWeb, :live_view

  alias Phoenix.PubSub
  alias Sorteios.Rooms
  alias Phoenix.LiveView.JS
  alias Sorteios.Rooms.Room
  alias Sorteios.Rooms.Prize
  alias SorteiosWeb.Presence

  @impl true
  def mount(%{"id" => id}, %{"name" => name, "email" => email} = session, socket) do
    Gettext.put_locale(SorteiosWeb.Gettext, session["locale"] || "en")

    if room = Rooms.get_room(id) do
      current_user = %{
        name: name,
        email: email
      }

      {:ok, _participant} = Rooms.create_participant(Map.put(current_user, :room_id, id))

      PubSub.subscribe(Sorteios.PubSub, topic(room))
      {:ok, _} = Presence.track(self(), topic(room), email, current_user)

      SorteiosWeb.Endpoint.subscribe(topic(room))

      invite_image =
        Routes.room_show_url(socket, :show, id)
        |> EQRCode.encode()
        |> EQRCode.svg(width: 400)

      socket =
        assign(
          socket,
          page_title: gettext("Room %{id}", id: id),
          admin?: session["admin:#{id}"] == id,
          id: id,
          room: room,
          current_user: current_user,
          loading_winner?: false,
          users: [],
          prizes: [],
          invite_image: invite_image,
          random_person: nil,
          editing_prize_id: nil,
          drawing_prize_id: nil,
          reservation_token: nil
        )

      {:ok,
       socket
       |> assign(:changeset, Rooms.change_prize(%Prize{}))
       |> reload_users()
       |> reload_prizes()
       |> restore_active_reservation()}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("Room not found"))
       |> redirect(to: Routes.session_path(socket, :new))}
    end
  end

  def mount(%{"id" => id}, session, socket) do
    Gettext.put_locale(SorteiosWeb.Gettext, session["locale"] || "en")

    {:ok,
     socket
     |> put_flash(:info, gettext("You need to specify your name and email to enter"))
     |> redirect(to: Routes.session_path(socket, :new, room_id: id))}
  end

  @impl true
  def handle_event("start_edit_prize", %{"prize-id" => id}, socket) do
    {:noreply, assign(socket, :editing_prize_id, id)}
  end

  def handle_event("cancel_edit_prize", _params, socket) do
    {:noreply, assign(socket, :editing_prize_id, nil)}
  end

  def handle_event("save_prize_name", %{"value" => name, "prize-id" => id}, socket) do
    prize = Rooms.get_prize!(id)
    name = String.trim(name)

    if name == "" or name == prize.name do
      {:noreply, assign(socket, :editing_prize_id, nil)}
    else
      case Rooms.update_prize(prize, %{name: name}) do
        {:ok, _prize} ->
          PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

          {:noreply,
           socket
           |> assign(:editing_prize_id, nil)
           |> reload_prizes()}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  @impl true
  def handle_event("quick_add_prize", _params, socket) do
    count = length(socket.assigns.prizes) + 1
    name = "#{ordinal(count)} Prize"
    prize_params = %{"name" => name, "room_id" => socket.assigns.id}

    case Rooms.create_prize(prize_params) do
      {:ok, _prize} ->
        PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

        {:noreply,
         socket
         |> reload_prizes()
         |> put_flash(:info, gettext("Prize created successfully"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("create_prize", %{"prize" => prize_params}, socket) do
    prize_params = Map.put(prize_params, "room_id", socket.assigns.id)

    quantity = String.to_integer(prize_params["quantity"])

    for count <- 1..quantity do
      name =
        if quantity == 1 do
          prize_params["name"]
        else
          "#{prize_params["name"]} ##{count}"
        end

      updated_params = Map.put(prize_params, "name", name)

      case Rooms.create_prize(updated_params) do
        {:ok, _prize} ->
          PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

          {:noreply,
           socket
           |> reload_prizes()
           |> put_flash(:info, gettext("Prize created successfully"))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    end
  end

  def handle_event("clone_prize", %{"prize-id" => prize_id}, socket) do
    prize = Rooms.get_prize!(prize_id)
    prize_params = %{"name" => prize.name, "room_id" => socket.assigns.id}

    case Rooms.create_prize(prize_params) do
      {:ok, _prize} ->
        PubSub.broadcast!(Sorteios.PubSub, topic(socket), "reload_prizes")

        {:noreply,
         socket
         |> reload_prizes()
         |> put_flash(:info, gettext("Prize cloned successfully"))}

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
         |> put_flash(:info, gettext("Prize removed successfully"))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("draw_prize", %{"prize-id" => prize_id}, socket) do
    Rooms.clear_prize_winner_reservation(
      socket.assigns.drawing_prize_id,
      socket.assigns.reservation_token
    )

    reservation_token = Ecto.UUID.generate()
    Process.send_after(self(), {:run_search, prize_id, reservation_token}, 3000)

    PubSub.broadcast_from!(Sorteios.PubSub, self(), topic(socket), %{
      event: "draw_started",
      prize_id: prize_id,
      reservation_token: reservation_token
    })

    {:noreply,
     assign(socket,
       drawing_prize_id: prize_id,
       reservation_token: reservation_token,
       loading_winner?: true,
       random_person: nil
     )}
  end

  def handle_event("confirm_prize_winner", %{"prize-id" => prize_id}, socket) do
    if active_draw?(socket, prize_id, socket.assigns.reservation_token) &&
         socket.assigns.random_person do
      {:noreply, award_prize(socket, prize_id, socket.assigns.reservation_token)}
    else
      {:noreply, put_flash(socket, :error, gettext("No prize or winner found"))}
    end
  end

  def handle_event("cancel_draw", _params, socket) do
    Rooms.clear_prize_winner_reservation(
      socket.assigns.drawing_prize_id,
      socket.assigns.reservation_token
    )

    PubSub.broadcast_from!(Sorteios.PubSub, self(), topic(socket), %{
      event: "draw_cancelled",
      prize_id: socket.assigns.drawing_prize_id,
      reservation_token: socket.assigns.reservation_token
    })

    {:noreply, clear_active_draw(socket)}
  end

  @impl true
  def handle_info({:run_search, prize_id, reservation_token}, socket) do
    if active_draw?(socket, prize_id, reservation_token) do
      case Rooms.reserve_prize_winner(
             prize_id,
             socket.assigns.id,
             socket.assigns.current_user.email,
             reservation_token
           ) do
        {:error, reason} ->
          PubSub.broadcast_from!(Sorteios.PubSub, self(), topic(socket), %{
            event: "draw_cancelled",
            prize_id: prize_id,
            reservation_token: reservation_token
          })

          {:noreply,
           socket
           |> clear_active_draw()
           |> reload_prizes()
           |> put_flash(:error, draw_error_message(reason))}

        {:ok, random_person} ->
          PubSub.broadcast_from!(Sorteios.PubSub, self(), topic(socket), %{
            event: "draw_result",
            prize_id: prize_id,
            person: random_person,
            reservation_token: reservation_token
          })

          {:noreply, assign(socket, random_person: random_person, loading_winner?: false)}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_info({:run_search, prize_id}, socket) do
    handle_info({:run_search, prize_id, socket.assigns.reservation_token}, socket)
  end

  def handle_info(
        %{event: "draw_started", prize_id: prize_id, reservation_token: reservation_token},
        socket
      ) do
    {:noreply,
     assign(socket,
       drawing_prize_id: prize_id,
       reservation_token: reservation_token,
       loading_winner?: true,
       random_person: nil
     )}
  end

  def handle_info(
        %{
          event: "draw_result",
          prize_id: prize_id,
          person: person,
          reservation_token: reservation_token
        },
        socket
      ) do
    if active_draw?(socket, prize_id, reservation_token) do
      {:noreply, assign(socket, random_person: person, loading_winner?: false)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "draw_result", person: person}, socket) do
    {:noreply, assign(socket, random_person: person, loading_winner?: false)}
  end

  def handle_info(%{event: "draw_started", prize_id: _prize_id}, socket) do
    {:noreply, socket |> clear_active_draw() |> reload_prizes()}
  end

  def handle_info(
        %{event: "draw_cancelled", prize_id: prize_id, reservation_token: reservation_token},
        socket
      ) do
    if active_draw?(socket, prize_id, reservation_token) do
      {:noreply, clear_active_draw(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "draw_cancelled"}, socket) do
    {:noreply, clear_active_draw(socket)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, reload_users(socket)}
  end

  def handle_info(
        %{event: "winner", winner: winner, prize: prize, reservation_token: reservation_token},
        socket
      ) do
    socket = reload_prizes(socket)

    if active_draw?(socket, prize.id, reservation_token) do
      {:noreply,
       socket
       |> clear_active_draw()
       |> put_flash(
         :success,
         gettext("%{winner} won %{prize}", winner: winner.name, prize: prize.name)
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "winner", winner: winner, prize: prize}, socket) do
    {:noreply,
     socket
     |> reload_prizes()
     |> clear_active_draw()
     |> put_flash(
       :success,
       gettext("%{winner} won %{prize}", winner: winner.name, prize: prize.name)
     )}
  end

  def handle_info("reload_prizes", socket) do
    {:noreply, reload_prizes(socket)}
  end

  defp topic(%{assigns: %{room: room}}), do: topic(room)
  defp topic(%Room{id: id}), do: "room:#{id}"

  def award_prize(socket, prize_id, reservation_token) do
    case Rooms.confirm_prize_winner(prize_id, reservation_token) do
      {:ok, prize} ->
        winner = %{name: prize.winner_name, email: prize.winner_email}

        PubSub.broadcast!(Sorteios.PubSub, topic(socket), %{
          event: "winner",
          winner: winner,
          prize: prize,
          reservation_token: reservation_token
        })

        socket
        |> assign(:random_person, nil)
        |> assign(:drawing_prize_id, nil)
        |> assign(:reservation_token, nil)
        |> reload_prizes()

      {:error, reason} ->
        PubSub.broadcast_from!(Sorteios.PubSub, self(), topic(socket), %{
          event: "draw_cancelled",
          prize_id: prize_id,
          reservation_token: reservation_token
        })

        socket
        |> clear_active_draw()
        |> reload_prizes()
        |> put_flash(:error, draw_error_message(reason))
    end
  end

  def reload_prizes(socket) do
    socket
    |> assign(:prizes, Rooms.list_prizes(socket.assigns.id))
    |> filter_available_prizes()
  end

  defp active_draw?(socket, prize_id, reservation_token) do
    socket.assigns.drawing_prize_id == prize_id &&
      socket.assigns.reservation_token == reservation_token &&
      not is_nil(reservation_token)
  end

  defp restore_active_reservation(%{assigns: %{admin?: true}} = socket) do
    case Rooms.get_active_reservation(socket.assigns.id) do
      nil ->
        socket

      prize ->
        assign(socket,
          drawing_prize_id: prize.id,
          reservation_token: prize.reservation_token,
          loading_winner?: false,
          random_person: %{name: prize.reserved_winner_name, email: prize.reserved_winner_email}
        )
    end
  end

  defp restore_active_reservation(socket), do: socket

  defp clear_active_draw(socket) do
    assign(socket,
      drawing_prize_id: nil,
      reservation_token: nil,
      loading_winner?: false,
      random_person: nil
    )
  end

  defp draw_error_message(:prize_unavailable),
    do: gettext("This prize is currently reserved; try again later")

  defp draw_error_message(:draw_in_progress),
    do: "Another draw is waiting to be assigned or cancelled"

  defp draw_error_message(:reservation_expired),
    do: gettext("The draw expired; please draw again")

  defp draw_error_message(_reason), do: gettext("No prize or winner found")

  def compute_chance(users_length) do
    if users_length > 0 do
      100 / users_length
    else
      0.0
    end
  end

  def reload_users(socket) do
    users = Rooms.list_participants_for_room(socket.assigns.id)

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

  defp ordinal(1), do: "1st"
  defp ordinal(2), do: "2nd"
  defp ordinal(3), do: "3rd"
  defp ordinal(n) when n in 4..20, do: "#{n}th"

  defp ordinal(n) do
    case rem(n, 10) do
      1 -> "#{n}st"
      2 -> "#{n}nd"
      3 -> "#{n}rd"
      _ -> "#{n}th"
    end
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
          <p class="text-sm font-medium text-gray-900">{@user.name}</p>
          <%= if @show_email? do %>
            <p class="truncate text-sm text-gray-500">{@user.email}</p>
          <% end %>
        </a>
      </div>
    </div>
    """
  end
end
