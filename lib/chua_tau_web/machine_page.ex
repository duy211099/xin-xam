defmodule ChuaTauWeb.MachinePage do
  @moduledoc """
  Serves a self-contained machine figure page from `priv/<slug>/index.html`.

  Only `</head>` is touched, and it must appear exactly once. The figure's own
  `<title>` is dropped and replaced by the SEO head tags.
  """

  alias ChuaTauWeb.Seo

  @slugs ~w(giai-nghiep cau-nang)

  def slugs, do: @slugs

  def path(slug) when slug in @slugs,
    do: Application.app_dir(:chua_tau, "priv/#{slug}/index.html")

  def load! do
    for slug <- @slugs, do: :persistent_term.put(key(slug), read!(slug))
    :ok
  end

  @spec parse!(binary()) :: %{head: binary(), tail: binary()}
  def parse!(html) do
    case :binary.matches(html, "</head>") do
      [{at, _}] ->
        %{head: binary_part(html, 0, at), tail: binary_part(html, at, byte_size(html) - at)}

      found ->
        raise ArgumentError, "expected exactly one </head>, found #{length(found)}"
    end
  end

  @spec render(String.t(), %Seo{}) :: iodata()
  def render(slug, %Seo{} = seo) do
    parts = parts(slug)

    [
      Regex.replace(~r{<title>.*?</title>}s, parts.head, "", global: false),
      Seo.render(seo),
      parts.tail
    ]
  end

  defp read!(slug) do
    parse!(File.read!(path(slug)))
  rescue
    e in ArgumentError -> reraise ArgumentError, "#{slug} page: #{e.message}", __STACKTRACE__
  end

  defp key(slug), do: {__MODULE__, slug}

  defp parts(slug) do
    if Application.get_env(:chua_tau, :reload_figure, false),
      do: read!(slug),
      else: :persistent_term.get(key(slug))
  end
end
