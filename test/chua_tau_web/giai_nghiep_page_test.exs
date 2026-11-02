defmodule ChuaTauWeb.GiaiNghiepPageTest do
  use ExUnit.Case, async: true

  alias ChuaTauWeb.GiaiNghiepPage

  @ok "<html><head><title>x</title></head><body></body></html>"

  test "accepts a page with one </head>" do
    assert %{head: _, tail: "</head>" <> _} = GiaiNghiepPage.parse!(@ok)
  end

  test "the shipped figure page parses" do
    assert %{} = GiaiNghiepPage.parse!(File.read!(GiaiNghiepPage.path()))
  end

  test "raises when </head> is missing" do
    assert_raise ArgumentError, ~r/exactly one <\/head>, found 0/, fn ->
      GiaiNghiepPage.parse!(String.replace(@ok, "</head>", ""))
    end
  end

  test "raises when </head> is duplicated" do
    assert_raise ArgumentError, ~r/exactly one <\/head>, found 2/, fn ->
      GiaiNghiepPage.parse!(@ok <> "</head>")
    end
  end
end
