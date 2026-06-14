defmodule TaskMaster.Jobs.TaskJobTest do
  use TaskMaster.DataCase
  use Oban.Testing, repo: TaskMaster.Repo

  import Mox
  import TaskMaster.TasksFixtures

  alias TaskMaster.Jobs.TaskJob
  alias TaskMaster.MockTaskProcessor
  alias TaskMaster.Tasks

  setup :verify_on_exit!

  describe "enqueue/1" do
    test "inserts job" do
      task = task_without_job()

      assert {:ok, _job} = TaskJob.enqueue(task)

      assert_enqueued(worker: TaskJob, args: %{task_id: task.id})
    end
  end

  describe "perform/2" do
    test "successful run" do
      task = task_without_job()
      expect(MockTaskProcessor, :process, fn _task -> {:ok, task} end)

      assert :ok = perform_job(TaskJob, %{"task_id" => task.id})
    end

    test "failed run with more attempts" do
      task = task_without_job()
      expect(MockTaskProcessor, :process, 2, fn _task -> {:error, "Something went wrong"} end)

      assert :ok = perform_job(TaskJob, %{"task_id" => task.id})

      assert :ok = perform_job(TaskJob, %{"task_id" => task.id})
    end

    test "failed at max_attempts cancels job" do
      task = task_without_job(%{max_attempts: 2})
      expect(MockTaskProcessor, :process, 2, fn _task -> {:error, "Something went wrong"} end)

      assert :ok = perform_job(TaskJob, %{"task_id" => task.id})

      # should have new job inserted
      assert_enqueued(worker: TaskJob, args: %{"task_id" => task.id})
      number_enqueued = length(all_enqueued())

      assert :ok = perform_job(TaskJob, %{"task_id" => task.id})

      {:ok, task} = Tasks.get_task(task.id)
      assert task.status == :failed
      assert length(task.attempts) == 2
      assert number_enqueued == length(all_enqueued())
    end
  end
end
