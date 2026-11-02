defmodule ChuaTauWeb.MetaController do
  @moduledoc "sitemap.xml, robots.txt and the web manifest."
  use ChuaTauWeb, :controller

  alias ChuaTau.Fortunes
  alias ChuaTauWeb.{Certificate, Machines, Seo}

  def sitemap(conn, _params) do
    share_paths =
      for c <- Fortunes.all(),
          {n, %{sample: false}} <- Enum.sort(c.entries),
          do: "/que/#{c.id}/#{n}"

    machine_paths =
      Enum.map(Machines.all(), &Machines.path/1)

    certificate_paths = for {loai, _} <- Certificate.kinds(), do: "/giai-nghiep/" <> loai

    urls =
      for path <- ["/" | machine_paths] ++ certificate_paths ++ share_paths do
        "  <url><loc>#{Plug.HTML.html_escape(Seo.absolute(path))}</loc></url>\n"
      end

    xml = [
      ~s(<?xml version="1.0" encoding="UTF-8"?>\n),
      ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n),
      urls,
      "</urlset>\n"
    ]

    conn |> put_resp_content_type("application/xml") |> send_resp(200, xml)
  end

  def robots(conn, _params) do
    body = "User-agent: *\nAllow: /\n\nSitemap: #{Seo.absolute("/sitemap.xml")}\n"
    conn |> put_resp_content_type("text/plain") |> send_resp(200, body)
  end

  def manifest(conn, _params) do
    manifest = %{
      name: Seo.site_name(),
      short_name: "Cổng chùa",
      lang: "vi",
      start_url: "/",
      display: "standalone",
      theme_color: "#b3261e",
      background_color: "#f3eee4",
      icons: [
        %{src: "/images/icon-192.png", sizes: "192x192", type: "image/png"},
        %{src: "/images/icon-512.png", sizes: "512x512", type: "image/png"}
      ]
    }

    conn
    |> put_resp_content_type("application/manifest+json")
    |> send_resp(200, Jason.encode!(manifest))
  end
end
