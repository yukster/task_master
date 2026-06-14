defmodule TaskMaster.Repo.Migrations.AddTaskEnumTypes do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE task_title_type AS ENUM ('import', 'export', 'report', 'cleanup')"
    execute "CREATE TYPE task_priority_type AS ENUM ('low', 'normal', 'high', 'critical')"
    execute "CREATE TYPE task_status_type AS ENUM ('queued', 'processing', 'completed', 'failed')"
  end

  def down do
    execute "DROP TYPE task_title_type"
    execute "DROP TYPE task_priority_type"
    execute "DROP TYPE task_status_type"
  end
end
