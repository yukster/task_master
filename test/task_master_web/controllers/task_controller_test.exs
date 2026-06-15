defmodule TaskMasterWeb.TaskControllerTest do
  use TaskMasterWeb.ConnCase

  import TaskMaster.TasksFixtures

  @create_attrs %{
    title: "some title",
    type: "import",
    priority: "normal",
    status: "queued",
    max_attempts: 5,
    payload: %{"foo" => "bar"}
  }

  @invalid_attrs %{
    priority: nil,
    status: nil,
    type: nil,
    max_attempts: nil,
    title: nil,
    payload: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all tasks", %{conn: conn} do
      task_fixture()
      conn = get(conn, ~p"/api/tasks")
      assert [task_json] = json_response(conn, 200)["data"]
      assert Map.has_key?(task_json, "id")
      assert Map.has_key?(task_json, "priority")
      assert Map.has_key?(task_json, "type")
    end

    test "filters by priority", %{conn: conn} do
      task_fixture(%{priority: :critical})
      task_fixture(%{priority: :high})
      task_fixture(%{status: :processing})

      conn = get(conn, ~p"/api/tasks", %{"priority" => "critical"})
      assert [task_json] = json_response(conn, 200)["data"]
      assert task_json["priority"] == "critical"
      assert Map.has_key?(task_json, "id")
    end

    test "filters by status", %{conn: conn} do
      task_fixture(%{status: :completed})
      task_fixture(%{priority: :high})
      task_fixture(%{status: :processing})

      conn = get(conn, ~p"/api/tasks", %{"status" => "processing"})
      assert [task_json] = json_response(conn, 200)["data"]
      assert task_json["status"] == "processing"
      assert Map.has_key?(task_json, "id")
    end

    test "filters by type", %{conn: conn} do
      task_fixture(%{type: :export})
      task_fixture(%{priority: :high})
      task_fixture(%{type: :cleanup})

      conn = get(conn, ~p"/api/tasks", %{"type" => "cleanup"})
      assert [task_json] = json_response(conn, 200)["data"]
      assert task_json["type"] == "cleanup"
      assert Map.has_key?(task_json, "id")
    end
  end

  describe "summary" do
    test "returns summary count of tasks per status", %{conn: conn} do
      task_fixture(%{status: :processing})
      task_fixture(%{status: :queued})
      task_fixture(%{status: :failed})
      task_fixture(%{status: :failed})

      conn = get(conn, ~p"/api/tasks/summary")

      assert json_response(conn, 200)["data"] == %{
               "completed" => 0,
               "failed" => 2,
               "processing" => 1,
               "queued" => 1
             }
    end
  end

  describe "create task" do
    test "renders task when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/tasks/#{id}")

      assert %{
               "id" => ^id,
               "max_attempts" => 5,
               "payload" => %{"foo" => "bar"},
               "priority" => "normal",
               "status" => "queued",
               "title" => "some title",
               "type" => "import"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/tasks", task: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "show task" do
    test "renders task when id is valid", %{conn: conn} do
      {:ok, task} = TaskMaster.Tasks.create_task(@create_attrs)
      conn = get(conn, ~p"/api/tasks/#{task}")
      id = task.id

      assert %{
               "id" => ^id,
               "max_attempts" => 5,
               "payload" => %{"foo" => "bar"},
               "priority" => "normal",
               "status" => "queued",
               "title" => "some title",
               "type" => "import"
             } = json_response(conn, 200)["data"]
    end

    test "renders 404 when id is invalid", %{conn: conn} do
      conn = get(conn, ~p"/api/tasks/non-existent-id")
      assert response(conn, 404)
      assert json_response(conn, 404)["errors"] == %{"detail" => "Not Found"}
    end
  end
end
