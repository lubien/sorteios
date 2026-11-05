defmodule Sorteios.RoomsTest do
  use Sorteios.DataCase

  alias Sorteios.Rooms

  describe "rooms" do
    alias Sorteios.Rooms.Room

    import Sorteios.RoomsFixtures

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Rooms.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "create_room/1 creates a room" do
      assert {:ok, %Room{}} = Rooms.create_room(%{})
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{}

      assert {:ok, %Room{} = _room} = Rooms.update_room(room, update_attrs)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Rooms.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room(room)
    end
  end

  describe "participants" do
    alias Sorteios.Rooms.Participant

    import Sorteios.RoomsFixtures

    @invalid_attrs %{email: nil, name: nil}

    test "list_participants/0 returns all participants" do
      participant = participant_fixture()
      assert Rooms.list_participants() == [participant]
    end

    test "get_participant!/1 returns the participant with given id" do
      participant = participant_fixture()
      assert Rooms.get_participant!(participant.id) == participant
    end

    test "create_participant/1 with valid data creates a participant" do
      room = room_fixture()
      valid_attrs = %{email: "some email", name: "some name", room_id: room.id}

      assert {:ok, %Participant{} = participant} = Rooms.create_participant(valid_attrs)
      assert participant.email == "some email"
      assert participant.name == "some name"
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant" do
      participant = participant_fixture()
      update_attrs = %{email: "some updated email", name: "some updated name"}

      assert {:ok, %Participant{} = participant} =
               Rooms.update_participant(participant, update_attrs)

      assert participant.email == "some updated email"
      assert participant.name == "some updated name"
    end

    test "update_participant/2 with invalid data returns error changeset" do
      participant = participant_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_participant(participant, @invalid_attrs)
      assert participant == Rooms.get_participant!(participant.id)
    end

    test "delete_participant/1 deletes the participant" do
      participant = participant_fixture()
      assert {:ok, %Participant{}} = Rooms.delete_participant(participant)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_participant!(participant.id) end
    end

    test "change_participant/1 returns a participant changeset" do
      participant = participant_fixture()
      assert %Ecto.Changeset{} = Rooms.change_participant(participant)
    end
  end

  describe "prize winner reservations" do
    import Sorteios.RoomsFixtures

    test "only one prize per room can be reserved at a time" do
      room = room_fixture()
      first_prize = prize_fixture(room, %{name: "First Prize"})
      second_prize = prize_fixture(room, %{name: "Second Prize"})

      {:ok, first_participant} =
        Rooms.create_participant(%{
          name: "First Participant",
          email: "first@example.com",
          room_id: room.id
        })

      {:ok, second_participant} =
        Rooms.create_participant(%{
          name: "Second Participant",
          email: "second@example.com",
          room_id: room.id
        })

      assert {:ok, first_winner} =
               Rooms.reserve_prize_winner(
                 first_prize.id,
                 room.id,
                 "admin@example.com",
                 "first-token"
               )

      assert {:error, :draw_in_progress} =
               Rooms.reserve_prize_winner(
                 second_prize.id,
                 room.id,
                 "admin@example.com",
                 "second-token"
               )

      assert {:ok, _prize} = Rooms.confirm_prize_winner(first_prize.id, "first-token")

      assert {:ok, second_winner} =
               Rooms.reserve_prize_winner(
                 second_prize.id,
                 room.id,
                 "admin@example.com",
                 "second-token"
               )

      assert first_winner.email in [first_participant.email, second_participant.email]
      assert second_winner.email in [first_participant.email, second_participant.email]
      refute first_winner.email == second_winner.email
    end

    test "returns an error when no participant is eligible" do
      room = room_fixture()
      prize = prize_fixture(room, %{name: "Prize"})

      {:ok, _admin} =
        Rooms.create_participant(%{
          name: "Admin",
          email: "admin@example.com",
          room_id: room.id
        })

      assert {:error, :no_eligible_participant} =
               Rooms.reserve_prize_winner(prize.id, room.id, "admin@example.com", "token")

      assert Rooms.get_prize!(prize.id).reserved_winner_email == nil
    end

    test "a prize cannot be reserved twice" do
      room = room_fixture()
      prize = prize_fixture(room)

      {:ok, _participant} =
        Rooms.create_participant(%{
          name: "Participant",
          email: "participant@example.com",
          room_id: room.id
        })

      assert {:ok, _winner} =
               Rooms.reserve_prize_winner(prize.id, room.id, "admin@example.com", "token")

      assert {:error, :prize_unavailable} =
               Rooms.reserve_prize_winner(prize.id, room.id, "admin@example.com", "other-token")
    end

    test "another prize can be reserved once the active draw is cancelled or expires" do
      room = room_fixture()
      first_prize = prize_fixture(room, %{name: "First Prize"})
      second_prize = prize_fixture(room, %{name: "Second Prize"})
      third_prize = prize_fixture(room, %{name: "Third Prize"})

      {:ok, _participant} =
        Rooms.create_participant(%{
          name: "Participant",
          email: "participant@example.com",
          room_id: room.id
        })

      assert {:ok, _winner} =
               Rooms.reserve_prize_winner(first_prize.id, room.id, "admin@example.com", "first")

      Rooms.clear_prize_winner_reservation(first_prize.id, "first")

      assert {:ok, _winner} =
               Rooms.reserve_prize_winner(second_prize.id, room.id, "admin@example.com", "second")

      expired_at = DateTime.add(DateTime.utc_now(), -301, :second)

      assert {:ok, _prize} =
               Rooms.update_prize(Rooms.get_prize!(second_prize.id), %{reserved_at: expired_at})

      assert {:ok, _winner} =
               Rooms.reserve_prize_winner(third_prize.id, room.id, "admin@example.com", "third")
    end

    test "returns errors when the room or prize no longer exists" do
      room = room_fixture()

      assert {:error, :room_not_found} =
               Rooms.reserve_prize_winner(
                 Ecto.UUID.generate(),
                 Ecto.UUID.generate(),
                 "admin",
                 "token"
               )

      assert {:error, :prize_not_found} =
               Rooms.reserve_prize_winner(Ecto.UUID.generate(), room.id, "admin", "token")

      assert {:error, :prize_not_found} =
               Rooms.confirm_prize_winner(Ecto.UUID.generate(), "token")
    end

    test "does not confirm an expired reservation" do
      room = room_fixture()
      prize = prize_fixture(room)

      {:ok, _participant} =
        Rooms.create_participant(%{
          name: "Participant",
          email: "participant@example.com",
          room_id: room.id
        })

      assert {:ok, _winner} =
               Rooms.reserve_prize_winner(prize.id, room.id, "admin@example.com", "token")

      expired_at = DateTime.add(DateTime.utc_now(), -301, :second)
      prize = Rooms.get_prize!(prize.id)
      assert {:ok, _prize} = Rooms.update_prize(prize, %{reserved_at: expired_at})

      assert {:error, :reservation_expired} = Rooms.confirm_prize_winner(prize.id, "token")
      assert is_nil(Rooms.get_prize!(prize.id).winner_email)
    end

    test "returns a changeset error when a winner already won in the room" do
      room = room_fixture()
      first_prize = prize_fixture(room)
      second_prize = prize_fixture(room)

      assert {:ok, _first_prize} =
               Rooms.update_prize(first_prize, %{
                 winner_name: "Winner",
                 winner_email: "winner@example.com"
               })

      assert {:error, changeset} =
               Rooms.update_prize(second_prize, %{
                 winner_name: "Winner",
                 winner_email: "winner@example.com"
               })

      assert changeset.errors[:winner_email]
    end
  end
end
