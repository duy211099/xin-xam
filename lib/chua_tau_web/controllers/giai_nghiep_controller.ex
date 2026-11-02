defmodule ChuaTauWeb.GiaiNghiepController do
  use ChuaTauWeb, :controller

  alias ChuaTauWeb.{Certificate, GiaiNghiepPage, Seo}

  plug :put_root_layout, html: {ChuaTauWeb.Layouts, :root}
  plug :put_layout, false

  def machine(conn, _params) do
    conn
    |> put_root_layout(false)
    |> put_resp_content_type("text/html")
    |> send_resp(200, GiaiNghiepPage.render())
  end

  def show(conn, %{"loai" => loai}) do
    case Certificate.label(loai) do
      nil ->
        not_found(conn)

      label ->
        render(conn, :show,
          label: label,
          seo: Seo.certificate(loai, label),
          stylesheet: "/css/certificate.css"
        )
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_root_layout(false)
    |> put_view(html: ChuaTauWeb.ErrorHTML)
    |> render("404.html")
  end
end
