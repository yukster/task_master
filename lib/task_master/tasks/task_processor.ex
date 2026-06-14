defmodule TaskMaster.Tasks.TaskProcessor do
  @moduledoc """
  Behaviour for Mox mocking the task processing logic
  """
  @callback process(Task.t()) :: {:ok, Task.t()} | {:error, String.t()}
end
