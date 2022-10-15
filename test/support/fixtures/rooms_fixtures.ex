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
      |> Enum.into(%{

      })
      |> Sorteios.Rooms.create_room()

    room
  end
end
