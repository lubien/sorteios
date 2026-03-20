defmodule Sorteios.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sorteios.Rooms` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{})
      |> Sorteios.Rooms.create_room()

    room
  end

  @doc """
  Generate a unique participant email.
  """
  def unique_participant_email, do: "some email#{System.unique_integer([:positive])}"

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    room = room_fixture()

    {:ok, participant} =
      attrs
      |> Enum.into(%{
        email: unique_participant_email(),
        name: "some name",
        room_id: room.id
      })
      |> Sorteios.Rooms.create_participant()

    participant
  end

  @doc """
  Generate a prize for a given room.
  """
  def prize_fixture(room, attrs \\ %{}) do
    {:ok, prize} =
      attrs
      |> Enum.into(%{
        name: "Test Prize",
        room_id: room.id
      })
      |> Sorteios.Rooms.create_prize()

    prize
  end
end
