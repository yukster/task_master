defmodule TaskMaster.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TaskMasterWeb.Telemetry,
      TaskMaster.Repo,
      {DNSCluster, query: Application.get_env(:task_master, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:task_master, Oban)},
      {Phoenix.PubSub, name: TaskMaster.PubSub},
      # Start a worker by calling: TaskMaster.Worker.start_link(arg)
      # {TaskMaster.Worker, arg},
      # Start to serve requests, typically the last entry
      TaskMasterWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TaskMaster.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TaskMasterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
