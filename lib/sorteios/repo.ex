defmodule Sorteios.Repo do
  use Ecto.Repo,
    otp_app: :sorteios,
    adapter: Ecto.Adapters.Postgres
end
