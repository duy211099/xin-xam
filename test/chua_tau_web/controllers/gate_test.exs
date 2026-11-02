defmodule ChuaTauWeb.GateTest do
  use ChuaTauWeb.ConnCase, async: true

  alias ChuaTauWeb.Machines

  test "GET / lists every machine in order", %{conn: conn} do
    doc = conn |> get(~p"/") |> html_response(200) |> Floki.parse_document!()
    links = Floki.find(doc, "a.machine")

    assert Enum.flat_map(links, &Floki.attribute(&1, "href")) == ["/xin-xam", "/giai-nghiep"]

    for {link, m} <- Enum.zip(links, Machines.all()) do
      assert Floki.text(link) =~ m.name
      assert [m.thumb] == link |> Floki.find("img") |> Floki.attribute("src")
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
      conn = get(conn, "/?#{key}=lu-to&free=1")
      assert redirected_to(conn, 302) == "/xin-xam?#{key}=lu-to&free=1"
    end

    conn = get(conn, "/?col=lu-to&free=1")
    assert redirected_to(conn, 302) == "/xin-xam?col=lu-to&free=1"
  end

  test "unrelated query params keep the gate", %{conn: conn} do
    assert conn |> get("/?utm_source=fb") |> html_response(200) =~ "a class=\"machine\""
  end
end
