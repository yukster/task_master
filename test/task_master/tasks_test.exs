defmodule TaskMaster.TasksTest do
  use TaskMaster.DataCase, async: true

  import Mox
  import TaskMaster.TasksFixtures

  alias TaskMaster.MockTaskProcessor
  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task

  @invalid_attrs %{
    "priority" => nil,
    "status" => nil,
    "type" => nil,
    "max_attempts" => nil,
    "title" => nil,
    "payload" => nil
  }

  describe "list_tasks/0" do
    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
    end

    test "filters by status" do
      task_with_direct_insert(%{"status" => "queued"})
      task_with_direct_insert(%{"status" => "completed"})

      list = Tasks.list_tasks(%{"status" => "completed"})
      assert [task] = list
      assert task.status == :completed
    end

    test "filters by priority" do
      task_fixture(%{"priority" => "low"})
      task_fixture(%{"priority" => "critical"})

      list = Tasks.list_tasks(%{"priority" => "low"})
      assert [task] = list
      assert task.priority == :low
    end

    test "filters by type" do
      task_fixture(%{"type" => "export"})
      task_fixture(%{"type" => "cleanup"})

      list = Tasks.list_tasks(%{"type" => "export"})
      assert [task] = list
      assert task.type == :export
    end

    test "sorted with critical first" do
      task_fixture(%{"priority" => "low"})
      task_fixture(%{"priority" => "critical"})
      task_fixture(%{"priority" => "high"})

      list = Tasks.list_tasks()
      assert [first, _second, _third] = list
      assert first.priority == :critical
    end

    # skipping test of the inserted_at ordering for time's sake
  end

  describe "summarize_tasks" do
    test "summary/0 returns counts by status" do
      task_with_direct_insert(%{"status" => "queued"})
      task_with_direct_insert(%{"status" => "queued"})
      task_with_direct_insert(%{"status" => "completed"})

      assert Tasks.summarize() == %{
               queued: 2,
               processing: 0,
               completed: 1,
               failed: 0
             }
    end
  end

  describe "get_task/1" do
    test "returns the task with given id" do
      task = task_fixture()
      assert Tasks.get_task(task.id) == {:ok, task}
    end

    test "returns error when task is not found" do
      assert Tasks.get_task("non-existent-id") == {:error, :not_found}
    end
  end

  describe "create_task/1" do
    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{
        "title" => "some title",
        "type" => "import",
        "priority" => "normal",
        "max_attempts" => 5,
        "payload" => %{"foo" => "bar"}
      }

      assert {:ok, %Task{} = task} = Tasks.create_task(valid_attrs)
      assert task.priority == :normal
      assert task.status == :queued
      assert task.type == :import
      assert task.max_attempts == 5
      assert task.title == "some title"
      assert task.payload == %{"foo" => "bar"}
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tasks.create_task(@invalid_attrs)
    end
  end

  describe "update_task/2" do
    test "update_task/2 with valid data updates the task" do
      task = task_fixture()

      refute task.status == :processing

      update_attrs = %{
        status: :processing,
        attempts: [
          %{
            started_at: DateTime.utc_now(),
            ended_at: DateTime.utc_now(),
            result: :completed,
            error: nil
          }
        ]
      }

      assert {:ok, %Task{} = task} = Tasks.update_task(task, update_attrs)
      assert task.status == :processing
      assert [task_attempt] = task.attempts
      assert task_attempt.result == :completed
      assert task_attempt.error == nil
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, @invalid_attrs)
      assert {:ok, task} = Tasks.get_task(task.id)
      assert task.title != "some updated title"
    end
  end

  describe "run_task/1" do
    test "runs a task and updates status to completed on success" do
      task = task_fixture()

      expect(MockTaskProcessor, :process, fn _task -> {:ok, task} end)

      assert {:ok, %Task{} = task} = Tasks.run_task(task)
      assert task.status == :completed
      assert [attempt] = task.attempts
      assert attempt.result == :completed
    end

    test "runs a task and updates status to queued on error if attempts remain" do
      # fixture max_attempts is 5
      task = task_fixture()

      expect(MockTaskProcessor, :process, fn _task -> {:error, "Simulated task failure"} end)

      assert {:ok, %Task{} = task} = Tasks.run_task(task)
      assert task.status == :queued
      assert [attempt] = task.attempts
      assert attempt.result == :failed
      assert attempt.error == "Simulated task failure"
    end

    test "runs a task and updates status to failed on error if max attempts reached" do
      # create task with 1 max attempt so it fails immediately
      task =
        task_fixture(%{
          "max_attempts" => 2
        })

      expect(MockTaskProcessor, :process, 2, fn _task ->
        {:error, "Simulated task failure"}
      end)

      assert {:ok, %Task{} = task} = Tasks.run_task(task)
      assert task.status == :queued
      assert [attempt] = task.attempts
      assert attempt.result == :failed

      assert {:ok, %Task{} = task} = Tasks.run_task(task)
      assert task.status == :failed
      assert [_attempt1, attempt2] = task.attempts
      assert attempt2.result == :failed
      assert attempt2.error == "Simulated task failure"
    end
  end
end
