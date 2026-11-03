defmodule ChuaTauWeb.StaticPathTest do
  use ChuaTauWeb.ConnCase, async: true

  alias ChuaTauWeb.StaticPath

  defp hash(path) do
    file = Application.app_dir(:chua_tau, "priv/static" <> path)
    :crypto.hash(:md5, File.read!(file)) |> Base.encode16(case: :lower) |> binary_part(0, 8)
  end

  test "versions a static file by its contents" do
    assert StaticPath.versioned("/css/gate.css") == "/css/gate.css?v=" <> hash("/css/gate.css")
  end

  test "the gate links its stylesheet and machine images by version", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()
    assert ["/css/gate.css?v=" <> _] = Floki.attribute(doc, ~s(link[rel=stylesheet]), "href")

    for src <- Floki.attribute(doc, "a.machine img", "src") do
      [path, v] = String.split(src, "?v=")
      assert v == hash(path)
    end
  end

  test "share and error pages version share.css", %{conn: conn} do
    for code <- ~w(404 500) do
      html = Phoenix.Template.render_to_string(ChuaTauWeb.ErrorHTML, code, "html", [])
      assert html =~ "/css/share.css?v=" <> hash("/css/share.css")
    end

    doc = conn |> get("/que/quan-am/1") |> html_response(200) |> Floki.parse_document!()
    assert ["/css/share.css?v=" <> _] = Floki.attribute(doc, ~s(link[rel=stylesheet]), "href")
  end
end
