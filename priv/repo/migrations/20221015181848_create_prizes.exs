defmodule Sorteios.Repo.Migrations.CreatePrizes do
  use Ecto.Migration

  def change do
    create table(:prizes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :winner_name, :string
      add :winner_email, :string
      add :room_id, references(:rooms, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:prizes, [:room_id])
  end
end
