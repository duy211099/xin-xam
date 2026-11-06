defmodule ChuaTauWeb.CauNangController do
  use ChuaTauWeb, :controller

  alias ChuaTauWeb.{MachinePage, Seo}

  def machine(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, MachinePage.render("cau-nang", Seo.cau_nang()))
  end
end
