defmodule TaskMasterWeb.TaskController do
  use TaskMasterWeb, :controller

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task

  action_fallback TaskMasterWeb.FallbackController

  def index(conn, _params) do
    tasks = Tasks.list_tasks()
    render(conn, :index, tasks: tasks)
  end

  def create(conn, %{"task" => task_params}) do
    with {:ok, %Task{} = task} <- Tasks.create_task(task_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/tasks/#{task}")
      |> render(:show, task: task)
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, task} <- Tasks.get_task(id) do
      render(conn, :show, task: task)
    end
  end
end
