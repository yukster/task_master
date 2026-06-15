defmodule TaskMaster.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias TaskMaster.Jobs.TaskJob
  alias TaskMaster.Repo
  alias TaskMaster.Tasks.Task

  # if I had more time I would make this overridable so I could test it
  @index_limit 100

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks(filters \\ %{}) do
    Task
    |> filter_by_status(filters["status"])
    |> filter_by_type(filters["type"])
    |> filter_by_priority(filters["priority"])
    |> order_by([t],
      asc:
        fragment(
          "CASE t0.priority WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 WHEN 'low' THEN 4 END"
        ),
      desc: t.inserted_at
    )
    |> limit(@index_limit)
    |> Repo.all()
  end

  defp filter_by_status(query, nil), do: query

  defp filter_by_status(query, status),
    do: where(query, [t], t.status == ^String.to_existing_atom(status))

  defp filter_by_type(query, nil), do: query

  defp filter_by_type(query, type),
    do: where(query, [t], t.type == ^String.to_existing_atom(type))

  defp filter_by_priority(query, nil), do: query

  defp filter_by_priority(query, priority),
    do: where(query, [t], t.priority == ^String.to_existing_atom(priority))

  @doc """
  Returns a summary of how many Tasks are in each status
  """
  def sumamarize do
    defaults = %{queued: 0, processing: 0, completed: 0, failed: 0}

    from(t in Task, group_by: t.status, select: {t.status, count(t.id)})
    |> Repo.all()
    |> Map.new()
    |> then(&Map.merge(defaults, &1))
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
  Creates a task and its initial Oban job in a Multi.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs) do
    Multi.new()
    |> Multi.insert(:task, Task.create_changeset(%Task{}, attrs))
    |> Multi.run(:job, fn _repo, %{task: task} ->
      TaskJob.enqueue(task)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{task: task}} -> {:ok, task}
      {:error, :task, changeset, _} -> {:error, changeset}
      {:error, :job, reason, _} -> {:error, reason}
    end
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
  def run_task(%Task{} = task) do
    started_at = DateTime.utc_now()

    case start_task(task) do
      {:ok, task} ->
        finish_task(task, started_at, task_processor().process(task))

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

    status = calculate_status(task, result)

    update_attrs = %{
      status: status,
      attempts: old_attempts ++ [new_attempt]
    }

    if status == :queued do
      update_task_and_insert_job(task, update_attrs)
    else
      update_task_for_completion(task, update_attrs)
    end
  end

  defp update_task_for_completion(task, update_attrs) do
    case update_task(task, update_attrs) do
      {:ok, task} -> {:ok, task}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp update_task_and_insert_job(task, update_attrs) do
    Multi.new()
    |> Multi.update(:task, Task.update_changeset(task, update_attrs))
    |> Multi.run(:job, fn _repo, %{task: task} ->
      TaskJob.enqueue(task)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{task: task}} -> {:ok, task}
      {:error, :task, changeset, _} -> {:error, changeset}
      {:error, :job, reason, _} -> {:error, reason}
    end
  end

  defp calculate_status(task, {:error, _reason}) do
    # add one for the current attempt
    if length(task.attempts) + 1 >= task.max_attempts do
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

  defp task_processor do
    Application.get_env(:task_master, :task_processor)
  end
end
