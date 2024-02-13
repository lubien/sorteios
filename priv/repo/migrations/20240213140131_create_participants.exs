defmodule Sorteios.Repo.Migrations.CreateParticipants do
  use Ecto.Migration

  def change do
    create table(:participants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :name, :string
      add :room_id, references(:rooms, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create unique_index(:participants, [:email, :room_id])
    create index(:participants, [:room_id])
  end
end
