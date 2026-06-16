defmodule TaskMaster.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Tasks` context.
  """
  alias TaskMaster.Repo
  alias TaskMaster.Tasks.Task

  # add more fixtures for different types?
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        "title" => "my task title",
        "type" => "import",
        "priority" => "normal",
        "payload" => %{"foo" => "bar"},
        "max_attempts" => 5
      })
      |> TaskMaster.Tasks.create_task()

    task
  end

  # create_task also creates the job
  # but we need a task without job for testing job
  def task_without_job(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "title" => "other task title",
        "type" => "import",
        "priority" => "normal",
        "payload" => %{"foo" => "bar"},
        "max_attempts" => 5
      })

    {:ok, task} =
      %Task{}
      |> Task.create_changeset(attrs)
      |> Repo.insert()

    task
  end

  def task_with_direct_insert(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "title" => "other task title",
        "type" => "import",
        "priority" => "normal",
        "status" => "queued",
        "payload" => %{"foo" => "bar"},
        "max_attempts" => 5
      })

    {:ok, task} =
      %Task{}
      |> Ecto.Changeset.cast(attrs, [:title, :type, :priority, :status, :payload, :max_attempts])
      |> Repo.insert()

    task
  end
end
