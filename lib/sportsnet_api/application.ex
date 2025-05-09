defmodule SportsnetApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SportsnetApiWeb.Telemetry,
      SportsnetApi.Repo,
      {DNSCluster, query: Application.get_env(:sportsnet_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SportsnetApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SportsnetApi.Finch},
      # Start a worker by calling: SportsnetApi.Worker.start_link(arg)
      # {SportsnetApi.Worker, arg},
      # Start to serve requests, typically the last entry
      SportsnetApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SportsnetApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SportsnetApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
