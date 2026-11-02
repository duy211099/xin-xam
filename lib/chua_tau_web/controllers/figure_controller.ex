defmodule ChuaTauWeb.FigureController do
  use ChuaTauWeb, :controller

  alias ChuaTauWeb.FigurePage

  def xin_xam(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, FigurePage.render())
  end

  def fortunes(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ChuaTau.Fortunes.json())
  end
end
