defmodule TaskMaster.Tasks.TaskTest do
  use TaskMaster.DataCase

  import TaskMaster.TasksFixtures

  alias TaskMaster.Tasks.Task

  describe "create validations" do
    test "validates that payload cannot be an empty map" do
      changeset =
        Task.create_changeset(%Task{}, %{
          title: "Test Task",
          type: :import,
          priority: :normal,
          status: :queued,
          max_attempts: 3,
          payload: %{}
        })

      assert changeset.errors[:payload] == {"cannot be an empty map", []}
    end

    test "required fields must be present" do
      changeset = Task.create_changeset(%Task{}, %{})

      Enum.each([:title, :type, :priority, :status, :payload], fn field ->
        assert changeset.errors[field] == {"can't be blank", [validation: :required]}
      end)
    end

    test "max_attempts has default value" do
      changeset =
        Task.create_changeset(%Task{}, %{
          title: "Test Task",
          type: :import,
          priority: :normal,
          status: :queued,
          payload: %{"key" => "value"}
        })

      assert changeset.data.max_attempts == 3
    end

    test "allows valid payload" do
      changeset =
        Task.create_changeset(%Task{}, %{
          title: "Test Task",
          type: :import,
          priority: :normal,
          status: :queued,
          max_attempts: 3,
          payload: %{"key" => "value"}
        })

      assert changeset.valid?
    end
  end

  describe "update" do
    test "allows embedding attempts" do
      task = task_fixture()

      changeset =
        Task.update_changeset(task, %{
          status: :processing,
          attempts: [
            %{
              started_at: DateTime.utc_now(),
              ended_at: DateTime.utc_now(),
              result: :completed,
              error: nil
            }
          ]
        })

      assert changeset.valid?
      assert length(changeset.changes.attempts) == 1
    end
  end
end
