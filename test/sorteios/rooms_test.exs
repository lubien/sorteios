defmodule Sorteios.RoomsTest do
  use Sorteios.DataCase

  alias Sorteios.Rooms

  describe "rooms" do
    alias Sorteios.Rooms.Room

    import Sorteios.RoomsFixtures

    @invalid_attrs %{}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Rooms.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{}

      assert {:ok, %Room{} = room} = Rooms.create_room(valid_attrs)
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{}

      assert {:ok, %Room{} = room} = Rooms.update_room(room, update_attrs)
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room(room, @invalid_attrs)
      assert room == Rooms.get_room!(room.id)
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
      valid_attrs = %{email: "some email", name: "some name"}

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

      assert {:ok, %Participant{} = participant} = Rooms.update_participant(participant, update_attrs)
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
end
