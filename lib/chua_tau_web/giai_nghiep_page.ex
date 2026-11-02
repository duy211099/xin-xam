defmodule ChuaTauWeb.GiaiNghiepPage do
  @moduledoc """
  Serves the self-contained figure page in `priv/giai-nghiep/index.html`.

  Only `</head>` is touched, and it must appear exactly once. The figure's own
  `<title>` is dropped and replaced by the SEO head tags.
  """

  alias ChuaTauWeb.Seo

  @key {__MODULE__, :parts}

  def path, do: Application.app_dir(:chua_tau, "priv/giai-nghiep/index.html")

  def load! do
    :persistent_term.put(@key, parse!(File.read!(path())))
    :ok
  end

  @spec parse!(binary()) :: %{head: binary(), tail: binary()}
  def parse!(html) do
    case :binary.matches(html, "</head>") do
      [{at, _}] ->
        %{head: binary_part(html, 0, at), tail: binary_part(html, at, byte_size(html) - at)}

      found ->
        raise ArgumentError,
              "giai nghiep page: expected exactly one </head>, found #{length(found)}"
    end
  end

  @spec render() :: iodata()
  def render do
    parts = parts()

    [
      Regex.replace(~r{<title>.*?</title>}s, parts.head, "", global: false),
      Seo.render(Seo.giai_nghiep()),
      parts.tail
    ]
  end

  defp parts do
    if Application.get_env(:chua_tau, :reload_figure, false) do
      parse!(File.read!(path()))
    else
      :persistent_term.get(@key)
    end
  end
end
