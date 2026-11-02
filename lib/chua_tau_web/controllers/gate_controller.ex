defmodule ChuaTauWeb.GateController do
  use ChuaTauWeb, :controller

  alias ChuaTauWeb.{Machines, Seo}

  @figure_params ~w(col free pal labels xr welcome phase press step)

  plug :fetch_query_params
  plug :put_root_layout, html: {ChuaTauWeb.Layouts, :root}
  plug :put_layout, false

  def home(conn, _params) do
    if Enum.any?(@figure_params, &Map.has_key?(conn.query_params, &1)) do
      redirect(conn, to: "/xin-xam?" <> conn.query_string)
    else
      render(conn, :home,
        machines: Machines.all(),
        seo: Seo.gate(),
        stylesheet: "/css/gate.css"
      )
    end
  end
end
