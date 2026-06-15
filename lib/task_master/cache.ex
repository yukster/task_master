defmodule TaskMaster.Cache do
  @moduledoc """
  Simple initial cache module (relying on Nebulex)
  """
  use Nebulex.Cache, otp_app: :task_master, adapter: Nebulex.Adapters.Local
end
