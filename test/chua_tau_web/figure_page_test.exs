defmodule ChuaTauWeb.FigurePageTest do
  use ExUnit.Case, async: true

  alias ChuaTauWeb.FigurePage

  @ok ~s(<html><head></head><body><script id="ct-fortunes" type="application/json">{}</script></body></html>)

  test "accepts a page with each marker once" do
    assert %{} = FigurePage.parse!(@ok)
  end

  test "the shipped figure page has the markers" do
    assert %{} = FigurePage.parse!(File.read!(FigurePage.path()))
  end

  test "raises when a marker is missing" do
    assert_raise ArgumentError, ~r/exactly one <\/head>, found 0/, fn ->
      FigurePage.parse!(String.replace(@ok, "</head>", ""))
    end
  end

  test "raises when a marker is duplicated" do
    assert_raise ArgumentError, ~r/exactly one <\/body>, found 2/, fn ->
      FigurePage.parse!(@ok <> "</body>")
    end
  end
end
