defmodule ChuaTauWeb.MachinePageTest do
  use ExUnit.Case, async: true

  alias ChuaTauWeb.MachinePage

  @ok "<html><head><title>x</title></head><body></body></html>"

  test "accepts a page with one </head>" do
    assert %{head: _, tail: "</head>" <> _} = MachinePage.parse!(@ok)
  end

  for slug <- MachinePage.slugs() do
    test "the shipped #{slug} page parses" do
      assert %{} = MachinePage.parse!(File.read!(MachinePage.path(unquote(slug))))
    end
  end

  test "raises when </head> is missing" do
    assert_raise ArgumentError, ~r/exactly one <\/head>, found 0/, fn ->
      MachinePage.parse!(String.replace(@ok, "</head>", ""))
    end
  end

  test "raises when </head> is duplicated" do
    assert_raise ArgumentError, ~r/exactly one <\/head>, found 2/, fn ->
      MachinePage.parse!(@ok <> "</head>")
    end
  end
end
