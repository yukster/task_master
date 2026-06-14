defmodule TaskMaster.Tasks.TaskTest do
  use TaskMaster.DataCase

  alias TaskMaster.Tasks.Task

  describe "validations" do
    test "validates that payload cannot be an empty map" do
      changeset =
        Task.changeset(%Task{}, %{
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
      changeset = Task.changeset(%Task{}, %{})

      Enum.each([:title, :type, :priority, :status, :payload], fn field ->
        assert changeset.errors[field] == {"can't be blank", [validation: :required]}
      end)
    end

    test "max_attempts has default value" do
      changeset =
        Task.changeset(%Task{}, %{
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
        Task.changeset(%Task{}, %{
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
end
