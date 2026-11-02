defmodule ChuaTauWeb.GiaiNghiepTest do
  use ChuaTauWeb.ConnCase, async: true

  alias ChuaTauWeb.{Certificate, Seo}

  test "GET /giai-nghiep serves the figure with SEO", %{conn: conn} do
    html = conn |> get(~p"/giai-nghiep") |> html_response(200)
    doc = Floki.parse_document!(html)
    title = Seo.giai_nghiep().title

    assert [{"title", _, [^title]}] = Floki.find(doc, "title")
    assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
    assert String.ends_with?(url, "/giai-nghiep")
    assert html =~ "MÁY GIẢI NGHIỆP"
    refute html =~ "hóa đơn"
  end

  for {loai, label} <- Certificate.kinds() do
    test "GET /giai-nghiep/#{loai} shows the certificate", %{conn: conn} do
      loai = unquote(loai)
      label = unquote(label)
      html = conn |> get("/giai-nghiep/#{loai}") |> html_response(200)
      doc = Floki.parse_document!(html)

      assert html =~ "GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP"
      assert html =~ "Loại: #{label}"
      assert html =~ "Hiệu lực: đến lần sau."
      assert [img] = Floki.attribute(doc, ~s(meta[property="og:image"]), "content")
      assert String.ends_with?(img, "/images/giai-nghiep/#{loai}.png")
      assert Floki.find(doc, ~s(meta[name=robots])) == []
      assert ["/giai-nghiep"] = Floki.attribute(doc, "a.cert-button", "href")
      assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
      assert String.ends_with?(url, "/giai-nghiep/#{loai}")
    end
  end

  test "unknown kinds are 404", %{conn: conn} do
    for path <- ["/giai-nghiep/nang", "/giai-nghiep/THAN", "/giai-nghiep/x"] do
      assert conn |> get(path) |> html_response(404) =~ "KHÔNG TÌM THẤY"
    end
  end

  test "og images and stylesheet are served", %{conn: conn} do
    for path <- [
          "/images/giai-nghiep/than.png",
          "/images/giai-nghiep/khau.png",
          "/images/giai-nghiep/y.png",
          "/css/certificate.css"
        ] do
      assert conn |> get(path) |> response(200)
    end
  end
end
