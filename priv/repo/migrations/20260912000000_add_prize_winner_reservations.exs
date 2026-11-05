defmodule Sorteios.Repo.Migrations.AddPrizeWinnerReservations do
  use Ecto.Migration

  def change do
    alter table(:prizes) do
      add :reserved_winner_name, :string
      add :reserved_winner_email, :string
      add :reserved_at, :utc_datetime_usec
    end

    create index(:prizes, [:room_id, :reserved_winner_email])
  end
end
