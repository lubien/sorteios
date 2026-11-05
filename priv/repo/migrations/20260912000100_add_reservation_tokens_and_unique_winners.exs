defmodule Sorteios.Repo.Migrations.AddReservationTokensAndUniqueWinners do
  use Ecto.Migration

  def change do
    alter table(:prizes) do
      add :reservation_token, :string
    end

    execute("""
    WITH duplicate_winners AS (
      SELECT id,
             row_number() OVER (
               PARTITION BY room_id, winner_email
               ORDER BY inserted_at ASC, id ASC
             ) AS duplicate_number
      FROM prizes
      WHERE winner_email IS NOT NULL
    )
    UPDATE prizes
    SET winner_name = NULL, winner_email = NULL
    WHERE id IN (
      SELECT id FROM duplicate_winners WHERE duplicate_number > 1
    )
    """)

    create unique_index(:prizes, [:room_id, :winner_email],
             where: "winner_email IS NOT NULL",
             name: :prizes_room_id_winner_email_unique
           )
  end
end
