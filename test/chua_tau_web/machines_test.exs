defmodule ChuaTauWeb.MachinesTest do
  use ExUnit.Case, async: true

  alias ChuaTauWeb.Machines

  test "every machine has a scene point inside the box" do
    for m <- Machines.all() do
      assert {x, y} = m.scene
      for v <- [x, y], do: assert(is_number(v) and v >= 0 and v <= 100)
    end
  end

  test "every machine's image size matches its PNG" do
    for m <- Machines.all() do
      png = File.read!(Path.join("priv/static", m.thumb))
      <<_::binary-size(16), w::32, h::32, _::binary>> = png
      assert m.thumb_size == {w, h}
    end
  end
end
