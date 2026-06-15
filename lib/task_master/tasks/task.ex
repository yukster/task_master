defmodule TaskMaster.Tasks.Task do
  @moduledoc """
  Represents a task to be processed by the system.
  Tasks have a type, priority, status, and payload.
  """
  use TaskMaster.Schema

  @task_types [:import, :export, :report, :cleanup]
  @task_priorities [:low, :normal, :high, :critical]
  @task_statuses [:queued, :processing, :completed, :failed]
  @all_fields [:title, :type, :priority, :status, :payload, :max_attempts]

  # embedded schema for attempts
  defmodule Attempt do
    use Ecto.Schema

    embedded_schema do
      field :started_at, :utc_datetime_usec
      field :ended_at, :utc_datetime_usec
      field :result, Ecto.Enum, values: [:completed, :failed]
      field :error, :string
    end
  end

  schema "tasks" do
    field :title, :string
    field :type, Ecto.Enum, values: @task_types
    field :priority, Ecto.Enum, values: @task_priorities
    field :status, Ecto.Enum, values: @task_statuses
    field :payload, :map
    field :max_attempts, :integer, default: 3

    embeds_many :attempts, Attempt, on_replace: :delete

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def create_changeset(task, attrs) do
    task
    |> cast(attrs, @all_fields)
    |> validate_required(@all_fields)
    |> validate_payload_not_empty(:payload)
  end

  def update_changeset(task, attrs) do
    task
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> cast_embed(:attempts, with: &attempt_changeset/2)
  end

  ## private

  defp validate_payload_not_empty(changeset, field) do
    validate_change(changeset, field, fn current_field, value ->
      case value do
        %{} = map when map_size(map) == 0 ->
          [{current_field, "cannot be an empty map"}]

        _ ->
          []
      end
    end)
  end

  defp attempt_changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:started_at, :ended_at, :result, :error])
    |> validate_required([:started_at, :ended_at, :result])
    |> validate_error()
  end

  defp validate_error(changeset) do
    case get_field(changeset, :result) do
      :completed -> changeset
      :failed -> validate_required(changeset, [:error])
    end
  end
end
