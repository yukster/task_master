defmodule TaskMaster.Repo.Migrations.FixTaskAttemptsColumnType do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :attempts
      add :attempts, {:array, :map}, default: []
    end
  end
end
