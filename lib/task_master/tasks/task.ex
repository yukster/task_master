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

  schema "tasks" do
    field :title, :string
    field :type, Ecto.Enum, values: @task_types
    field :priority, Ecto.Enum, values: @task_priorities
    field :status, Ecto.Enum, values: @task_statuses
    field :payload, :map
    field :max_attempts, :integer, default: 3

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, @all_fields)
    |> validate_required(@all_fields)
    |> validate_payload_not_empty(:payload)
  end

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
end
