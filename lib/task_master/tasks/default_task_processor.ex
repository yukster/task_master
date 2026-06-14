defmodule TaskMaster.Tasks.DefaultTaskProcessor do
  @moduledoc """
  Default runtime task processing logic
  """
  @behaviour TaskMaster.Tasks.TaskProcessor

  @sleep_durations %{
    low: 6000..8000,
    normal: 4000..6000,
    high: 2000..4000,
    critical: 1000..2000
  }

  # simulates the work of a task with potential for failure
  # Use Mox to have no sleep and certainty for happy/sad tests
  @impl TaskMaster.Tasks.TaskProcessor
  def process(task) do
    # sleep amount based on priority
    :timer.sleep(Enum.random(@sleep_durations[task.priority]))

    # Simulate a 20% chance of failure
    if :rand.uniform() <= 0.2 do
      {:error, "Simulated task failure"}
    else
      {:ok, task}
    end
  end
end
