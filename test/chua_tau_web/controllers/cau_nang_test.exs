defmodule ChuaTauWeb.CauNangTest do
  use ChuaTauWeb.ConnCase, async: true

  alias ChuaTauWeb.Seo

  test "GET /cau-nang serves the shrine with SEO and the fixed slip", %{conn: conn} do
    html = conn |> get(~p"/cau-nang") |> html_response(200)
    doc = Floki.parse_document!(html)
    title = Seo.cau_nang().title

    assert [{"title", _, [^title]}] = Floki.find(doc, "title")
    assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
    assert String.ends_with?(url, "/cau-nang")
    assert html =~ "Trời sẽ nắng thôi"
    refute html =~ "ct-fortunes"
  end
end
