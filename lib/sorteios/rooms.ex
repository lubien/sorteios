defmodule Sorteios.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Sorteios.Repo

  alias Sorteios.Rooms.Room
  alias Sorteios.Rooms.Participant

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  def get_room(id) do
    try do
      Repo.get(Room, id)
    rescue
      Ecto.Query.CastError ->
        nil
    end
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  alias Sorteios.Rooms.Prize

  @doc """
  Returns the list of prizes.

  ## Examples

      iex> list_prizes()
      [%Prize{}, ...]

  """
  def list_prizes(room_id) do
    Prize
    |> where(room_id: ^room_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single prize.

  Raises `Ecto.NoResultsError` if the Prize does not exist.

  ## Examples

      iex> get_prize!(123)
      %Prize{}

      iex> get_prize!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prize!(id), do: Repo.get!(Prize, id)

  @doc """
  Creates a prize.

  ## Examples

      iex> create_prize(%{field: value})
      {:ok, %Prize{}}

      iex> create_prize(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prize(attrs \\ %{}) do
    %Prize{}
    |> Prize.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prize.

  ## Examples

      iex> update_prize(prize, %{field: new_value})
      {:ok, %Prize{}}

      iex> update_prize(prize, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prize(%Prize{} = prize, attrs) do
    prize
    |> Prize.changeset(attrs)
    |> Repo.update()
  end

  @reservation_ttl_seconds 300

  def reserve_prize_winner(prize_id, room_id, excluded_email, reservation_token) do
    Repo.transaction(fn ->
      if is_nil(Repo.one(from room in Room, where: room.id == ^room_id, lock: "FOR UPDATE")) do
        Repo.rollback(:room_not_found)
      end

      prize =
        Repo.one(
          from prize in Prize,
            where: prize.id == ^prize_id and prize.room_id == ^room_id,
            lock: "FOR UPDATE"
        )

      if is_nil(prize), do: Repo.rollback(:prize_not_found)

      cutoff = DateTime.add(DateTime.utc_now(), -@reservation_ttl_seconds, :second)

      prize =
        if prize.reserved_at && DateTime.compare(prize.reserved_at, cutoff) == :lt do
          prize
          |> Prize.changeset(%{
            reserved_winner_name: nil,
            reserved_winner_email: nil,
            reserved_at: nil,
            reservation_token: nil
          })
          |> Repo.update!()
        else
          prize
        end

      if prize.winner_email || prize.reserved_winner_email do
        Repo.rollback(:prize_unavailable)
      end

      # Only one draw per room may await confirmation at a time. The room lock
      # above serializes reservations, so this check cannot race.
      draw_in_progress? =
        Repo.exists?(
          from other in Prize,
            where:
              other.room_id == ^room_id and other.id != ^prize.id and
                not is_nil(other.reserved_winner_email) and other.reserved_at > ^cutoff
        )

      if draw_in_progress?, do: Repo.rollback(:draw_in_progress)

      claimed_emails =
        from claimed in Prize,
          where: claimed.room_id == ^room_id and not is_nil(claimed.winner_email),
          select: claimed.winner_email

      candidates =
        Participant
        |> where(
          [participant],
          participant.room_id == ^room_id and
            participant.email != ^excluded_email and
            participant.email not in subquery(claimed_emails)
        )
        |> Repo.all()

      if candidates == [], do: Repo.rollback(:no_eligible_participant)

      participant = Enum.random(candidates)

      prize
      |> Prize.changeset(%{
        reserved_winner_name: participant.name,
        reserved_winner_email: participant.email,
        reserved_at: DateTime.utc_now(),
        reservation_token: reservation_token
      })
      |> Repo.update!()

      participant
    end)
  end

  def confirm_prize_winner(prize_id, reservation_token) do
    Repo.transaction(fn ->
      prize =
        Repo.one(from prize in Prize, where: prize.id == ^prize_id, lock: "FOR UPDATE")

      if is_nil(prize), do: Repo.rollback(:prize_not_found)

      cutoff = DateTime.add(DateTime.utc_now(), -@reservation_ttl_seconds, :second)

      if prize.reservation_token != reservation_token do
        Repo.rollback(:winner_not_reserved)
      end

      if is_nil(prize.reserved_winner_email) || is_nil(prize.reserved_at) do
        Repo.rollback(:winner_not_reserved)
      end

      if DateTime.compare(prize.reserved_at, cutoff) != :gt do
        Repo.rollback(:reservation_expired)
      end

      changeset =
        Prize.changeset(prize, %{
          winner_name: prize.reserved_winner_name,
          winner_email: prize.reserved_winner_email,
          reserved_winner_name: nil,
          reserved_winner_email: nil,
          reserved_at: nil,
          reservation_token: nil
        })

      case Repo.update(changeset) do
        {:ok, prize} -> prize
        {:error, _changeset} -> Repo.rollback(:winner_conflict)
      end
    end)
  end

  def get_active_reservation(room_id) do
    cutoff = DateTime.add(DateTime.utc_now(), -@reservation_ttl_seconds, :second)

    Prize
    |> where(
      [prize],
      prize.room_id == ^room_id and is_nil(prize.winner_email) and
        not is_nil(prize.reserved_winner_email) and not is_nil(prize.reservation_token) and
        prize.reserved_at > ^cutoff
    )
    |> order_by(desc: :reserved_at)
    |> limit(1)
    |> Repo.one()
  end

  def clear_prize_winner_reservation(nil, _reservation_token), do: :ok

  def clear_prize_winner_reservation(prize_id, reservation_token) do
    Prize
    |> where(
      [prize],
      prize.id == ^prize_id and prize.reservation_token == ^reservation_token
    )
    |> Repo.update_all(
      set: [
        reserved_winner_name: nil,
        reserved_winner_email: nil,
        reserved_at: nil,
        reservation_token: nil
      ]
    )
  end

  @doc """
  Deletes a prize.

  ## Examples

      iex> delete_prize(prize)
      {:ok, %Prize{}}

      iex> delete_prize(prize)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prize(%Prize{} = prize) do
    Repo.delete(prize)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prize changes.

  ## Examples

      iex> change_prize(prize)
      %Ecto.Changeset{data: %Prize{}}

  """
  def change_prize(%Prize{} = prize, attrs \\ %{}) do
    Prize.changeset(prize, attrs)
  end

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants do
    Repo.all(Participant)
  end

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants_for_room(room_id) do
    Participant
    |> where(room_id: ^room_id)
    |> Repo.all()
  end

  @doc """
  Gets a single participant.

  Raises `Ecto.NoResultsError` if the Participant does not exist.

  ## Examples

      iex> get_participant!(123)
      %Participant{}

      iex> get_participant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_participant!(id), do: Repo.get!(Participant, id)

  @doc """
  Creates a participant.

  ## Examples

      iex> create_participant(%{field: value})
      {:ok, %Participant{}}

      iex> create_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert(
      on_conflict: [set: [name: attrs.name]],
      conflict_target: [:email, :room_id]
    )
  end

  @doc """
  Updates a participant.

  ## Examples

      iex> update_participant(participant, %{field: new_value})
      {:ok, %Participant{}}

      iex> update_participant(participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a participant.

  ## Examples

      iex> delete_participant(participant)
      {:ok, %Participant{}}

      iex> delete_participant(participant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_participant(%Participant{} = participant) do
    Repo.delete(participant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking participant changes.

  ## Examples

      iex> change_participant(participant)
      %Ecto.Changeset{data: %Participant{}}

  """
  def change_participant(%Participant{} = participant, attrs \\ %{}) do
    Participant.changeset(participant, attrs)
  end
end
