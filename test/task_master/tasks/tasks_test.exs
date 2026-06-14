defmodule TaskMaster.Tasks.TasksTest do
  use TaskMaster.DataCase

  alias TaskMaster.Tasks
  alias TaskMaster.Tasks.Task

  import TaskMaster.TasksFixtures

  @invalid_attrs %{
    priority: nil,
    status: nil,
    type: nil,
    max_attempts: nil,
    title: nil,
    payload: nil
  }

  describe "list_tasks/0" do
    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Tasks.list_tasks() == [task]
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
        title: "some title",
        type: "import",
        priority: "normal",
        status: "queued",
        max_attempts: 5,
        payload: %{"foo" => "bar"}
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

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Tasks.change_task(task)
    end
  end

  describe "update_task/2" do
    test "update_task/2 with valid data updates the task" do
      task = task_fixture()

      update_attrs = %{
        title: "some updated title",
        type: "export",
        priority: "high",
        status: "processing",
        max_attempts: 10,
        payload: %{"updated" => "data"}
      }

      assert {:ok, %Task{} = task} = Tasks.update_task(task, update_attrs)
      assert task.priority == :high
      assert task.status == :processing
      assert task.type == :export
      assert task.max_attempts == 10
      assert task.title == "some updated title"
      assert task.payload == %{"updated" => "data"}
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Tasks.update_task(task, @invalid_attrs)
      assert {:ok, task} = Tasks.get_task(task.id)
      assert task.title != "some updated title"
    end
  end
end
