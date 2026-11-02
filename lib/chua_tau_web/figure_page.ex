defmodule ChuaTauWeb.FigurePage do
  @moduledoc """
  Serves the self-contained figure page in `priv/figure/index.html`.

  The page is only ever touched at three markers: `</head>`, the body of
  `<script id="ct-fortunes" type="application/json">`, and `</body>`. Each must
  appear exactly once, in that order, or `load!/0` raises.
  """

  alias ChuaTauWeb.Seo

  @key {__MODULE__, :parts}
  @script_open ~s(<script id="ct-fortunes" type="application/json">)
  @script_close "</script>"

  @gate_link ~s(<style>.ct-gate-link{position:fixed;top:8px;left:8px;z-index:50;padding:4px 8px;font:13px/1.2 'Noto Serif','Times New Roman',Georgia,serif;color:#2b1a10;background:#f3eee4;border:2px solid #2b1a10;border-radius:4px;text-decoration:none}</style><a class="ct-gate-link" href="/">← Cổng chùa</a>)

  @type parts :: %{
          head: binary(),
          between: binary(),
          after_json: binary(),
          tail: binary()
        }

  def path, do: Application.app_dir(:chua_tau, "priv/figure/index.html")

  def load! do
    :persistent_term.put(@key, parse!(File.read!(path())))
    :ok
  end

  @spec parse!(binary()) :: parts()
  def parse!(html) do
    for marker <- ["</head>", @script_open, "</body>"] do
      count = length(:binary.matches(html, marker))

      if count != 1,
        do: raise(ArgumentError, "figure page: expected exactly one #{marker}, found #{count}")
    end

    {head_at, _} = :binary.match(html, "</head>")
    {open_at, open_len} = :binary.match(html, @script_open)
    {body_at, _} = :binary.match(html, "</body>")
    json_from = open_at + open_len

    close_at =
      case :binary.match(html, @script_close, scope: {json_from, byte_size(html) - json_from}) do
        {at, _} -> at
        :nomatch -> raise ArgumentError, "figure page: the ct-fortunes script is never closed"
      end

    unless head_at < open_at and close_at < body_at,
      do:
        raise(
          ArgumentError,
          "figure page: markers must appear in the order </head>, ct-fortunes, </body>"
        )

    %{
      head: binary_part(html, 0, head_at),
      between: binary_part(html, head_at, json_from - head_at),
      after_json: binary_part(html, close_at, body_at - close_at),
      tail: binary_part(html, body_at, byte_size(html) - body_at)
    }
  end

  @doc "Builds the page around `json`, the fortune JSON already encoded with `escape: :html_safe`."
  @spec render(binary()) :: iodata()
  def render(json), do: assemble(parts(), json)

  def render, do: render(ChuaTau.Fortunes.json())

  defp assemble(parts, json) do
    [
      Regex.replace(~r{<title>.*?</title>}s, parts.head, "", global: false),
      Seo.render(Seo.xin_xam()),
      parts.between,
      json,
      parts.after_json,
      @gate_link,
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
