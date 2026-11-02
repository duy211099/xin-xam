defmodule ChuaTau.Fortune do
  @moduledoc "One fortune slip. `generated` entries have no written text and come from `ChuaTau.Fortunes.Sample`."

  @enforce_keys [:number, :title, :category, :poem, :interpretation, :advice, :sample, :generated]
  @derive Jason.Encoder
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          number: pos_integer(),
          title: String.t(),
          category: String.t(),
          poem: [String.t()],
          interpretation: String.t(),
          advice: String.t(),
          sample: boolean(),
          generated: boolean()
        }
end
