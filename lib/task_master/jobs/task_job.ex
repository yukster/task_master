defmodule TaskMaster.Jobs.TaskJob do
  @moduledoc """
  Oban Job for running Tasks
  """
  use Oban.Worker,
    # thought about distinct queues per priority but that means four workers
    # I would probably do that in a real app though
    queue: :default,
    # just doing a single attempt since we will queue a new job if under max attempts
    max_attempts: 1

  # no uniqueness needed as jobs are enqued by internal logic and only one will be in flight at a time

  require Logger

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task

  def enqueue(%Task{id: task_id}) do
    %{task_id: task_id}
    |> new()
    |> Oban.insert()
  end

  # note that Task model is handling retry logic instead of Oban
  def perform(%Oban.Job{args: %{"task_id" => task_id}}) do
    with {:ok, task} <- Tasks.get_task(task_id),
         {:ok, task} <- Tasks.run_task(task) do
      Logger.info("Task #{task.id} attempt completed: #{inspect(task)}")
      :ok
    else
      {:error, :not_found} ->
        # If the task is not found (should not happen) cancel the job
        {:cancel, "Task not found"}

      {:error, %Ecto.Changeset{} = changeset} ->
        message = "DB action failed: #{inspect(changeset.errors)}"
        Logger.warning("Task #{changeset.data.id} failed: #{message}")
        {:cancel, message}

      {:error, reason} ->
        Logger.warning("Task failure with reason: #{reason}")
        {:cancel, reason}
    end
  end
end
