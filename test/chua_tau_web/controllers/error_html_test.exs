defmodule ChuaTauWeb.ErrorHTMLTest do
  use ChuaTauWeb.ConnCase, async: true

  import Phoenix.Template

  test "renders a Vietnamese 404.html" do
    assert render_to_string(ChuaTauWeb.ErrorHTML, "404", "html", []) =~ "KHÔNG TÌM THẤY"
  end

  test "renders a Vietnamese 500.html" do
    assert render_to_string(ChuaTauWeb.ErrorHTML, "500", "html", []) =~ "CÓ LỖI XẢY RA"
  end
end
