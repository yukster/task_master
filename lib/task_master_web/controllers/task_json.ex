defmodule TaskMasterWeb.TaskJSON do
  alias TaskMaster.Tasks.Task

  @doc """
  Renders a list of tasks.
  """
  def index(%{tasks: tasks}) do
    %{data: for(task <- tasks, do: data(task))}
  end

  @doc """
  Renders a single task.
  """
  def show(%{task: task}) do
    %{data: data(task)}
  end

  defp data(%Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      type: task.type,
      priority: task.priority,
      status: task.status,
      payload: task.payload,
      max_attempts: task.max_attempts
    }
  end

  def summary(%{summary: summary}) do
    %{data: summary}
  end
end
