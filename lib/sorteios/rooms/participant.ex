defmodule Sorteios.Rooms.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "participants" do
    field :email, :string
    field :name, :string
    field :room_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:email, :name, :room_id])
    |> validate_required([:email, :name, :room_id])
    |> unique_constraint(:email)
  end
end
