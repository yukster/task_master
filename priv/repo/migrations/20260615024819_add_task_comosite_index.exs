defmodule TaskMaster.Repo.Migrations.AddTaskComositeIndex do
  use Ecto.Migration

  # opted for individual indexes rather than a composite because
  # I read that Postgres is smart enough to combine them
  def up do
    create_if_not_exists index(:tasks, [:status])
    create_if_not_exists index(:tasks, [:type])
    create_if_not_exists index(:tasks, [:priority])
  end

  def down do
    drop_if_exists index(:tasks, [:status])
    drop_if_exists index(:tasks, [:type])
    drop_if_exists index(:tasks, [:priority])
  end
end
