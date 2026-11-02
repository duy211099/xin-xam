defmodule ChuaTauWeb.PagesTest do
  use ChuaTauWeb.ConnCase, async: true

  defp fortune_json(html) do
    [_, body] =
      Regex.run(~r{<script id="ct-fortunes" type="application/json">(.*?)</script>}s, html)

    {body, Jason.decode!(body)}
  end

  describe "GET /" do
    test "serves the figure with the full fortune JSON", %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)
      {_, data} = fortune_json(html)

      assert [%{"collection" => "quan-am"}, %{"collection" => "lu-to"}] = data["collections"]

      for c <- data["collections"] do
        assert c["total"] == 100
        assert c["generateSamples"] == false
        assert Enum.map(c["fortunes"], & &1["number"]) == Enum.to_list(1..100)
      end

      [quan_am, lu_to] = data["collections"]
      refute quan_am["sample"]
      refute Enum.any?(quan_am["fortunes"], &(&1["sample"] or &1["generated"]))
      assert hd(quan_am["fortunes"])["title"] == "Chung Ly thành đạo"
      refute lu_to["sample"]
      refute Enum.any?(lu_to["fortunes"], &(&1["sample"] or &1["generated"]))
      assert hd(lu_to["fortunes"])["title"] == "Vương Mẫu chúc thọ"
      refute html =~ "mẫu)"
    end

    test "has SEO tags, and one title", %{conn: conn} do
      html = conn |> get(~p"/") |> html_response(200)
      doc = Floki.parse_document!(html)

      assert [{"title", _, ["Xin xăm online · Quan Âm Linh Xăm 100 quẻ"]}] =
               Floki.find(doc, "title")

      assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
      assert String.starts_with?(url, "http://localhost") and String.ends_with?(url, "/")
      assert [_] = Floki.attribute(doc, ~s(meta[name=description]), "content")
      assert ["vi_VN"] = Floki.attribute(doc, ~s(meta[property="og:locale"]), "content")
      assert ["website"] = Floki.attribute(doc, ~s(meta[property="og:type"]), "content")
      assert [img] = Floki.attribute(doc, ~s(meta[property="og:image"]), "content")
      assert String.ends_with?(img, "/images/og.png") and String.starts_with?(img, "http")

      assert ["summary_large_image"] =
               Floki.attribute(doc, ~s(meta[name="twitter:card"]), "content")

      assert ["/manifest.webmanifest"] = Floki.attribute(doc, ~s(link[rel=manifest]), "href")
      assert [_] = Floki.attribute(doc, ~s(link[rel=apple-touch-icon]), "href")
      assert Floki.find(doc, ~s(meta[name=robots])) == []
      assert html =~ ~s("@type":"WebSite")
      assert Floki.find(doc, ".ct-intro") == []
    end
  end

  describe "injected JSON" do
    test "cannot close the script tag" do
      collection = %ChuaTau.Collection{
        id: "x",
        name: "</script><b>boom</b>",
        total: 1,
        sample: false,
        entries: %{}
      }

      json = ChuaTau.Fortunes.encode([collection])
      refute json =~ "</script"

      page = ChuaTauWeb.FigurePage.render(json) |> IO.iodata_to_binary()
      {body, data} = fortune_json(page)
      refute body =~ "</"
      assert hd(data["collections"])["name"] == "</script><b>boom</b>"
    end
  end

  describe "GET /que/:set/:n" do
    test "shows a written fortune, indexable", %{conn: conn} do
      html = conn |> get(~p"/que/quan-am/1") |> html_response(200)
      doc = Floki.parse_document!(html)

      assert html =~ "Chung Ly thành đạo"
      assert html =~ "Khai thiên tịch địa tác lương duyên"
      assert html =~ "Quẻ số 1 / 100"
      assert html =~ "Quẻ tốt"
      assert html =~ "Lời giải"
      assert html =~ "Lời khuyên"
      refute html =~ "Nội dung mẫu"
      assert Floki.find(doc, ~s(meta[name=robots])) == []
      assert ["/?col=quan-am"] = Floki.attribute(doc, ~s(a.slip-button), "href")
      assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
      assert String.ends_with?(url, "/que/quan-am/1")
    end

    test "404 for an unknown set or a number outside the set", %{conn: conn} do
      for path <- [
            "/que/nope/1",
            "/que/quan-am/0",
            "/que/quan-am/101",
            "/que/quan-am/abc",
            "/que/quan-am/5x"
          ] do
        assert conn |> get(path) |> html_response(404) =~ "KHÔNG TÌM THẤY"
      end
    end
  end

  describe "site files" do
    test "sitemap lists home and the written, non-sample fortunes only", %{conn: conn} do
      conn = get(conn, ~p"/sitemap.xml")
      assert response_content_type(conn, :xml) =~ "xml"
      body = response(conn, 200)
      assert length(Regex.scan(~r{<loc>}, body)) == 201
      assert body =~ ~r{<loc>http://localhost[^<]*/</loc>}
      assert body =~ ~r{<loc>http://localhost[^<]*/que/quan-am/100</loc>}
      assert body =~ "/que/lu-to/100"
    end

    test "robots.txt allows all and points at the sitemap", %{conn: conn} do
      body = conn |> get(~p"/robots.txt") |> response(200)
      assert body =~ "Allow: /"
      assert body =~ ~r{Sitemap: http://localhost[^\s]*/sitemap.xml}
    end

    test "manifest", %{conn: conn} do
      m = conn |> get(~p"/manifest.webmanifest") |> response(200) |> Jason.decode!()
      assert m["name"] == "Máy xin xăm online"
      assert m["short_name"] == "Xin xăm"
      assert m["lang"] == "vi"
      assert m["display"] == "standalone"
      assert m["theme_color"] == "#b3261e"
      assert m["background_color"] == "#f3eee4"
      assert Enum.map(m["icons"], & &1["src"]) == ["/images/icon-192.png", "/images/icon-512.png"]
    end

    test "icons and og image are served", %{conn: conn} do
      for path <- [
            "/images/icon-192.png",
            "/images/icon-512.png",
            "/images/og.png",
            "/css/share.css"
          ] do
        assert conn |> get(path) |> response(200)
      end
    end

    test "/api/fortunes matches the page JSON", %{conn: conn} do
      api = conn |> get(~p"/api/fortunes") |> json_response(200)
      {_, page} = conn |> get(~p"/") |> html_response(200) |> fortune_json()
      assert api == page
    end
  end
end
