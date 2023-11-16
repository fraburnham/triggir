defmodule Triggir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TriggirWeb.Telemetry,
      Triggir.Repo,
      {DNSCluster, query: Application.get_env(:triggir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Triggir.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Triggir.Finch},
      # Start a worker by calling: Triggir.Worker.start_link(arg)
      # {Triggir.Worker, arg},
      {Triggir.TaskManager, %{max_workers: 20}},
      # Start to serve requests, typically the last entry
      TriggirWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Triggir.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TriggirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
