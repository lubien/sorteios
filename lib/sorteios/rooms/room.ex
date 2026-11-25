defmodule Sorteios.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :allow_multiple_prizes, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:allow_multiple_prizes])
    |> validate_required([:allow_multiple_prizes])
  end
end
