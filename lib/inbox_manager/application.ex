defmodule InboxManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InboxManagerWeb.Telemetry,
      InboxManager.Repo,
      {DNSCluster, query: Application.get_env(:inbox_manager, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: InboxManager.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: InboxManager.Finch},
      # Start Oban for background job processing
      {Oban, Application.fetch_env!(:inbox_manager, Oban)},
      # Start a worker by calling: InboxManager.Worker.start_link(arg)
      # {InboxManager.Worker, arg},
      # Start to serve requests, typically the last entry
      InboxManagerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InboxManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InboxManagerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
