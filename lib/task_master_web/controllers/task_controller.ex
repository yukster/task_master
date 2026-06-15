defmodule TaskMasterWeb.TaskController do
  use TaskMasterWeb, :controller

  alias TaskMaster.Cache
  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task

  @summary_cache_key "task_summary"
  @ttl :timer.minutes(2)

  action_fallback TaskMasterWeb.FallbackController

  def index(conn, params) do
    # would have preferred to validate these params but...
    tasks = Tasks.list_tasks(params)
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

  def summary(conn, _params) do
    summary =
      case Cache.get(@summary_cache_key) do
        {:ok, nil} -> get_and_cache_summary()
        {:ok, summary} -> summary
      end

    render(conn, :summary, summary: summary)
  end

  defp get_and_cache_summary do
    summary = Tasks.summarize()
    Cache.put(@summary_cache_key, summary, ttl: @ttl)
    summary
  end
end
