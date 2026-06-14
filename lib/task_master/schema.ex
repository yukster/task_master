defmodule TaskMaster.Schema do
  @moduledoc """
  Base schema module that provides common functionality for all TaskMaster schemas.

  This module sets up:
  - NanoID string primary keys
  - Common imports and aliases
  - Consistent timestamps
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset

      @nanoid_size 16
      @nanoid_alphabet "123456789ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijklmnpqrstuvwxyz"

      @primary_key {:id, :string,
                    autogenerate: {Nanoid, :generate, [@nanoid_size, @nanoid_alphabet]}}
      @foreign_key_type :string
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
