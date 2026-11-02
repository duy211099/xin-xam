defmodule ChuaTauWeb.Seo do
  @moduledoc "Head tags shared by the figure page and the share pages."
  use Phoenix.Component

  @site_name "Máy xin xăm online"
  @home_title "Xin xăm online · Quan Âm Linh Xăm 100 quẻ"
  @home_description "Xin xăm online với máy xin xăm ảo: thành tâm khấn nguyện, bỏ đồng xu, nhận viên nang vàng rồi đọc lời xăm. Hai bộ Quan Âm và Lữ Tổ Linh Xăm, mỗi bộ 100 quẻ, có lời thơ, lời giải và lời khuyên."

  defstruct [:title, :description, :url, noindex: false, json_ld: nil]

  def site_name, do: @site_name

  def absolute(path), do: ChuaTauWeb.Endpoint.url() <> path

  def home do
    %__MODULE__{
      title: @home_title,
      description: @home_description,
      url: absolute("/"),
      json_ld:
        Jason.encode!(
          %{
            "@context" => "https://schema.org",
            "@type" => "WebSite",
            "name" => @site_name,
            "url" => absolute("/"),
            "inLanguage" => "vi"
          },
          escape: :html_safe
        )
    }
  end

  def render_home do
    assigns = %{seo: home()}

    ~H"<.head_tags seo={@seo} />"
    |> Phoenix.HTML.Safe.to_iodata()
  end

  attr :seo, __MODULE__, required: true

  def head_tags(assigns) do
    ~H"""
    <title>{@seo.title}</title>
    <meta name="description" content={@seo.description} />
    <link rel="canonical" href={@seo.url} />
    <%= if @seo.noindex do %>
      <meta name="robots" content="noindex" />
    <% end %>
    <meta property="og:type" content="website" />
    <meta property="og:locale" content="vi_VN" />
    <meta property="og:site_name" content={ChuaTauWeb.Seo.site_name()} />
    <meta property="og:title" content={@seo.title} />
    <meta property="og:description" content={@seo.description} />
    <meta property="og:url" content={@seo.url} />
    <meta property="og:image" content={absolute("/images/og.png")} />
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={@seo.title} />
    <meta name="twitter:description" content={@seo.description} />
    <meta name="twitter:image" content={absolute("/images/og.png")} />
    <meta name="theme-color" content="#b3261e" />
    <link rel="manifest" href="/manifest.webmanifest" />
    <link rel="icon" type="image/png" href="/images/icon-192.png" />
    <link rel="apple-touch-icon" href="/images/icon-192.png" />
    <%= if @seo.json_ld do %>
      <script type="application/ld+json">
        <%= Phoenix.HTML.raw(@seo.json_ld) %>
      </script>
    <% end %>
    """
  end
end
