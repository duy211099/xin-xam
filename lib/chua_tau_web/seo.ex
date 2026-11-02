defmodule ChuaTauWeb.Seo do
  @moduledoc "Head tags shared by the gate, the figure page and the share pages."
  use Phoenix.Component

  @site_name "Cổng chùa · Máy xin xăm và máy giải nghiệp"
  @gate_title "Cổng chùa · Máy xin xăm và máy giải nghiệp online"
  @gate_description "Cổng chùa online với hai chiếc máy: máy xin xăm ảo rút quẻ từ bộ Quan Âm và Lữ Tổ Linh Xăm, và máy giải nghiệp. Chọn một máy để bắt đầu."
  @xin_xam_title "Xin xăm online · Quan Âm Linh Xăm 100 quẻ"
  @xin_xam_description "Xin xăm online với máy xin xăm ảo: thành tâm khấn nguyện, bỏ đồng xu, nhận viên nang vàng rồi đọc lời xăm. Hai bộ Quan Âm và Lữ Tổ Linh Xăm, mỗi bộ 100 quẻ, có lời thơ, lời giải và lời khuyên."

  defstruct [:title, :description, :url, noindex: false, json_ld: nil, image: "/images/og.png"]

  def site_name, do: @site_name

  def absolute(path), do: ChuaTauWeb.Endpoint.url() <> path

  def xin_xam do
    %__MODULE__{
      title: @xin_xam_title,
      description: @xin_xam_description,
      url: absolute("/xin-xam")
    }
  end

  def gate do
    %__MODULE__{
      title: @gate_title,
      description: @gate_description,
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

  @spec render(%__MODULE__{}) :: iodata()
  def render(%__MODULE__{} = seo) do
    assigns = %{seo: seo}

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
    <meta property="og:image" content={absolute(@seo.image)} />
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={@seo.title} />
    <meta name="twitter:description" content={@seo.description} />
    <meta name="twitter:image" content={absolute(@seo.image)} />
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
