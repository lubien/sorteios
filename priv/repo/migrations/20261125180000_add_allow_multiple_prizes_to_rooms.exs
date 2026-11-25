defmodule Sorteios.Repo.Migrations.AddAllowMultiplePrizesToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :allow_multiple_prizes, :boolean, null: false, default: false
    end

    # Whether a person may win more than once is now a per-room setting, so it
    # can no longer be a database-wide unique index. It is enforced in
    # Sorteios.Rooms while holding the room row lock instead.
    drop unique_index(:prizes, [:room_id, :winner_email],
           where: "winner_email IS NOT NULL",
           name: :prizes_room_id_winner_email_unique
         )

    create index(:prizes, [:room_id, :winner_email])
  end
end
