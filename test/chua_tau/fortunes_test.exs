defmodule ChuaTau.FortunesTest do
  use ExUnit.Case, async: true

  alias ChuaTau.{Fortunes, Fortunes.Sample}

  @moduletag :tmp_dir

  defp valid(overrides) do
    Map.merge(
      %{
        "collection" => "demo",
        "name" => "Demo",
        "total" => 3,
        "fortunes" => [
          %{
            "number" => 1,
            "title" => "T",
            "category" => "good",
            "poem" => ["a"],
            "interpretation" => "i",
            "advice" => "d"
          }
        ]
      },
      overrides
    )
  end

  defp write(dir, name, data), do: File.write!(Path.join(dir, name), Jason.encode!(data))

  defp fortune(n),
    do: %{
      "number" => n,
      "title" => "T",
      "category" => "good",
      "poem" => ["a"],
      "interpretation" => "i",
      "advice" => "d"
    }

  test "loads the shipped data in order" do
    assert [%{id: "quan-am", total: 100}, %{id: "lu-to", total: 100}] =
             Fortunes.load_dir!(Fortunes.default_dir())
  end

  test "loads a good file and sorts by order then filename", %{tmp_dir: dir} do
    write(dir, "b.json", valid(%{"collection" => "b", "order" => 1}))
    write(dir, "a.json", valid(%{"collection" => "a", "order" => 2}))
    write(dir, "c.json", valid(%{"collection" => "c"}))
    assert {:ok, cols} = Fortunes.load_dir(dir)
    assert Enum.map(cols, & &1.id) == ["b", "a", "c"]
  end

  test "rejects a duplicate number", %{tmp_dir: dir} do
    write(dir, "bad.json", valid(%{"fortunes" => [fortune(1), fortune(1)]}))
    assert {:error, msg} = Fortunes.load_dir(dir)
    assert msg =~ "bad.json" and msg =~ "duplicate fortune number 1"
  end

  test "rejects a number above total", %{tmp_dir: dir} do
    write(dir, "bad.json", valid(%{"fortunes" => [fortune(4)]}))
    assert {:error, msg} = Fortunes.load_dir(dir)
    assert msg =~ "number 4 is outside 1..3"
  end

  test "rejects missing fields and bad JSON", %{tmp_dir: dir} do
    write(dir, "bad.json", valid(%{"fortunes" => [Map.delete(fortune(1), "advice")]}))
    assert {:error, msg} = Fortunes.load_dir(dir)
    assert msg =~ ~s("advice")

    File.write!(Path.join(dir, "bad.json"), "{nope")
    assert {:error, msg} = Fortunes.load_dir(dir)
    assert msg =~ "not valid JSON"
  end

  test "load_dir! raises with a clear message", %{tmp_dir: dir} do
    write(dir, "bad.json", valid(%{"total" => 0}))

    assert_raise ArgumentError, ~r/invalid fortune data: bad.json: "total"/, fn ->
      Fortunes.load_dir!(dir)
    end
  end

  test "generated samples are deterministic and marked" do
    a = Sample.entry("quan-am", 7)
    assert a == Sample.entry("quan-am", 7)
    assert a.sample and a.generated
    assert String.starts_with?(a.title, "(mẫu) ")
    assert a.category in ["good", "neutral", "bad"]
    assert length(a.poem) == 4
  end
end
