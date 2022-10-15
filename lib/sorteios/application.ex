defmodule Sorteios.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Sorteios.Repo,
      # Start the Telemetry supervisor
      SorteiosWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sorteios.PubSub},
      # Start the Endpoint (http/https)
      SorteiosWeb.Endpoint,
      SorteiosWeb.Presence
      # Start a worker by calling: Sorteios.Worker.start_link(arg)
      # {Sorteios.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sorteios.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SorteiosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
