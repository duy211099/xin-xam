defmodule ChuaTauWeb.StaticPath do
  @moduledoc """
  Static URLs with a content hash query (`/css/gate.css?v=1a2b3c4d`), so a CDN or
  browser cache never serves an old file next to new HTML. Hashes are cached for
  the life of the VM.
  """

  @spec versioned(String.t()) :: String.t()
  def versioned("/" <> _ = path) do
    key = {__MODULE__, path}

    case :persistent_term.get(key, nil) do
      nil ->
        url = path <> "?v=" <> hash(path)
        :persistent_term.put(key, url)
        url

      url ->
        url
    end
  end

  defp hash(path) do
    Application.app_dir(:chua_tau, "priv/static" <> path)
    |> File.read!()
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 8)
  end
end
