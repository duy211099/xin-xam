defmodule ChuaTauWeb.Seo do
  @moduledoc "Head tags shared by the gate, the figure page and the share pages."
  use Phoenix.Component

  @site_name "Cổng chùa · Máy xin xăm và máy giải nghiệp"
  @gate_title "Cổng chùa · Máy xin xăm và máy giải nghiệp online"
  @gate_description "Cổng chùa online với ba chiếc máy: máy xin xăm ảo rút quẻ từ bộ Quan Âm và Lữ Tổ Linh Xăm, máy giải nghiệp và miếu cầu nắng. Chọn một máy để bắt đầu."
  @xin_xam_title "Xin xăm online · Quan Âm Linh Xăm 100 quẻ"
  @xin_xam_description "Xin xăm online với máy xin xăm ảo: thành tâm khấn nguyện, bỏ đồng xu, nhận viên nang vàng rồi đọc lời xăm. Hai bộ Quan Âm và Lữ Tổ Linh Xăm, mỗi bộ 100 quẻ, có lời thơ, lời giải và lời khuyên."

  @giai_nghiep_title "Máy giải nghiệp online · Nhanh, gọn, có kết quả"
  @giai_nghiep_description "Máy giải nghiệp online: chọn nghiệp thân, khẩu hoặc ý, nhét tiền vào máy, đợi máy giải rồi nhận kết quả và giấy chứng nhận đã giải nghiệp. Nhanh, gọn, có kết quả."

  @cau_nang_title "Miếu cầu nắng online · Thắp nhang, rung chuông, chờ nắng lên"
  @cau_nang_description "Miếu cầu nắng online: thắp nhang, rung chuông, khấn một điều mong, đợi mây tan nắng lên rồi nhận phiếu cầu nắng."

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

  def giai_nghiep do
    %__MODULE__{
      title: @giai_nghiep_title,
      description: @giai_nghiep_description,
      url: absolute("/giai-nghiep")
    }
  end

  def cau_nang do
    %__MODULE__{
      title: @cau_nang_title,
      description: @cau_nang_description,
      url: absolute("/cau-nang")
    }
  end

  def certificate(loai, label) do
    %__MODULE__{
      title: "Giấy chứng nhận đã giải nghiệp · Loại #{label} · Máy giải nghiệp",
      description:
        "Giấy chứng nhận đã giải nghiệp, loại #{label}, hiệu lực đến lần sau. Tự giải nghiệp của mình ở máy giải nghiệp online.",
      url: absolute("/giai-nghiep/#{loai}"),
      image: "/images/giai-nghiep/#{loai}.png"
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
