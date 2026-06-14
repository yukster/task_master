defmodule TaskMaster.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      timestamps(type: :utc_datetime_usec)

      # using nanoid for shorter unique string IDs
      add :id, :string, primary_key: true
      add :title, :string, null: false
      add :type, :task_title_type, null: false
      add :priority, :task_priority_type, null: false
      add :status, :task_status_type, null: false
      add :payload, :map, null: false
      add :max_attempts, :integer, null: false, default: 3
      add :attempts, :map, null: false, default: %{}
    end
  end
end
