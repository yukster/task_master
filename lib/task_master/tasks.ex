defmodule TaskMaster.Tasks do
  @moduledoc """
  The Tasks context.
  """

  alias TaskMaster.Repo
  alias TaskMaster.Tasks.Task

  @sleep_durations %{
    low: 6000..8000,
    normal: 4000..6000,
    high: 2000..4000,
    critical: 1000..2000
  }

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    # needs limit or pagination!
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Returns `{:ok, task}` if the Task exists, otherwise `{:error, :not_found}`.

  ## Examples

      iex> get_task("b3fBIkvL6LtZMbuH")
      {:ok, %Task{}}

      iex> get_task("non-existent-id")
      {:error, :not_found}

  """
  def get_task(id) do
    case Repo.get(Task, id) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # this will need to insert the oban job as well, in a txn/multi
  def create_task(attrs) do
    %Task{}
    |> Task.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
    ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # under the covers, this needs to handle the attempt tracking too
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Runs a task.
  ## Examples

      iex> run_task(task)
      {:ok, %Task{}}

      iex> run_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def run_task(%Task{} = task, process_fn \\ &default_process/1) do
    started_at = DateTime.utc_now()

    case start_task(task) do
      {:ok, task} ->
        finish_task(task, started_at, process_fn.(task))

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  ## private functions

  defp start_task(task) do
    case update_task(task, %{status: :processing}) do
      {:ok, task} -> {:ok, task}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # result is either :ok or {:error, reason}
  defp finish_task(task, started_at, result) do
    new_attempt = %{
      started_at: started_at,
      ended_at: DateTime.utc_now(),
      result: attempt_result(result),
      error: attempt_error(result)
    }

    old_attempts =
      Enum.map(task.attempts, fn attempt ->
        Map.from_struct(attempt)
      end)

    update_attrs = %{
      status: calculate_status(task, result),
      attempts: old_attempts ++ [new_attempt]
    }

    case update_task(task, update_attrs) do
      {:ok, task} -> {:ok, task}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp calculate_status(task, {:error, _reason}) do
    # add one for the current attempt
    if length(task.attempts) + 1 == task.max_attempts do
      :failed
    else
      :queued
    end
  end

  defp calculate_status(_task, _result), do: :completed

  defp attempt_result({:ok, _task}), do: :completed
  defp attempt_result({:error, _reason}), do: :failed

  defp attempt_error({:ok, _task}), do: nil
  defp attempt_error({:error, reason}), do: reason

  # simulates the work of a task with potential for failure
  # Inject fn to have no sleep and certainty for happy/sad tests
  defp default_process(task) do
    # sleep amount based on priority
    :timer.sleep(Enum.random(@sleep_durations[task.priority]))

    # Simulate a 20% chance of failure
    if :rand.uniform() <= 0.2 do
      {:error, "Simulated task failure"}
    else
      {:ok, task}
    end
  end
end
