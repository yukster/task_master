defmodule TaskMaster.Tasks do
  @moduledoc """
  The Tasks context.
  """

  alias TaskMaster.Repo
  alias TaskMaster.Tasks.Task

  # add task lifecycle functions here
  # state machine is enforced by lifecycle functions
  # this also inserts and updates Attempts
  # lifecycle also results in summary metrics updating
  # which should invalidate the cache

  # create_task inserts the Task record and the Oban job; status defaults to :queued
  # start_task updates the Task status to :processing and inserts an Attempt with started_at

  # if attempt succeeds, complete_task updates the Task status to :completed
  # and updates the Attempt with ended_at and result
  # if attempt fails, fail_task updates the Task status back to :queued
  # and inserts an new Oban job for the next Attempt
  # (I kinda feel like I'm reimplementing Oban here)

  # these are the functions the Oban job can call; need throrough tests around these
  ##

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
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
end
