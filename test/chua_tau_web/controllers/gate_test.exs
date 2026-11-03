defmodule ChuaTauWeb.GateTest do
  use ChuaTauWeb.ConnCase, async: true

  alias ChuaTauWeb.Machines

  test "GET / lists every machine in order", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()
    links = Floki.find(doc, "a.machine")

    assert Enum.flat_map(links, &Floki.attribute(&1, "href")) == ["/xin-xam", "/giai-nghiep"]

    for {link, m} <- Enum.zip(links, Machines.all()) do
      assert Floki.text(link) =~ m.name
      assert [ChuaTauWeb.StaticPath.versioned(m.thumb)] == link |> Floki.find("img") |> Floki.attribute("src")
    end
  end

  test "each machine is placed at its scene point", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()

    for {link, m} <- Enum.zip(Floki.find(doc, "a.machine"), Machines.all()) do
      [style] = Floki.attribute(link, "style")
      {x, y} = m.scene
      assert style =~ "--x: #{x}%"
      assert style =~ "--y: #{y}%"
    end
  end

  test "the scene is decorative and holds no links", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()
    [svg] = Floki.find(doc, "svg.scene")
    assert Floki.attribute(svg, "aria-hidden") == ["true"]
    assert Floki.find(svg, "a") == []
    assert ["true", "true", "true"] == doc |> Floki.find("svg.vignette") |> Floki.attribute("aria-hidden")
  end

  test "each machine link appears once", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()

    for m <- Machines.all() do
      assert [_] = Floki.find(doc, ~s(a[href="#{Machines.path(m)}"]))
    end
  end

  test "GET / is a plain gate page", %{conn: conn} do
    html = conn |> get(~p"/") |> html_response(200)
    doc = Floki.parse_document!(html)
    refute html =~ "ct-fortunes"
    assert html =~ ~s("@type":"WebSite")
    assert [_] = Floki.find(doc, "title")
    assert [url] = Floki.attribute(doc, ~s(link[rel=canonical]), "href")
    assert String.ends_with?(url, "/")
  end

  test "old figure query links redirect to /xin-xam", %{conn: conn} do
    for key <- ~w(col free pal labels xr welcome phase press step) do
      conn = get(conn, "/?#{key}=1&utm_source=fb")
      assert redirected_to(conn, 302) == "/xin-xam?#{key}=1&utm_source=fb"
    end

    conn = get(conn, "/?col=lu-to&free=1")
    assert redirected_to(conn, 302) == "/xin-xam?col=lu-to&free=1"
  end

  test "unrelated query params keep the gate", %{conn: conn} do
    doc = conn |> get("/?utm_source=fb") |> html_response(200) |> Floki.parse_document!()
    assert [_, _] = Floki.find(doc, "a.machine")
  end
end
