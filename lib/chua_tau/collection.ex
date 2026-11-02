defmodule ChuaTau.Collection do
  @moduledoc "A set of fortune slips. `entries` holds only the written ones, keyed by number."

  alias ChuaTau.Fortune

  @enforce_keys [:id, :name, :total, :sample, :entries]
  defstruct [:id, :name, :total, :sample, :entries, order: nil]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          total: pos_integer(),
          sample: boolean(),
          order: integer() | nil,
          entries: %{pos_integer() => Fortune.t()}
        }
end
