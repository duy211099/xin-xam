defmodule ChuaTauWeb.Certificate do
  @moduledoc "The three kinds of giải nghiệp certificate."

  @kinds [{"than", "THÂN"}, {"khau", "KHẨU"}, {"y", "Ý"}]

  @spec kinds() :: [{String.t(), String.t()}]
  def kinds, do: @kinds

  @spec label(String.t()) :: String.t() | nil
  def label(loai), do: List.keyfind(@kinds, loai, 0) |> elem_label()

  defp elem_label({_, label}), do: label
  defp elem_label(nil), do: nil
end
