defmodule TaskMaster.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `TaskMaster.Tasks` context.
  """

  # add more fixtures for different types?
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        title: "my task title",
        type: "import",
        priority: "normal",
        status: "queued",
        payload: %{"foo" => "bar"},
        max_attempts: 5
      })
      |> TaskMaster.Tasks.create_task()

    task
  end
end
