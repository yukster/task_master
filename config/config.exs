# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :task_master, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: TaskMaster.Repo

config :task_master,
  ecto_repos: [TaskMaster.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :task_master, TaskMasterWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TaskMasterWeb.ErrorHTML, json: TaskMasterWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TaskMaster.PubSub,
  live_view: [signing_salt: "fvfKEsDh"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# yep, just straight copied from the hex docs :-p
config :task_master, TaskMaster.MyCache,
  gc_interval: :timer.hours(12),
  max_size: 1_000_000,
  allocated_memory: 2_000_000_000,
  gc_memory_check_interval: :timer.seconds(10)

config :task_master, :task_processor, TaskMaster.Tasks.DefaultTaskProcessor

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
