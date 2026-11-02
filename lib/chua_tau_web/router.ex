defmodule ChuaTauWeb.Router do
  use ChuaTauWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers
  end

  scope "/", ChuaTauWeb do
    get "/sitemap.xml", MetaController, :sitemap
    get "/robots.txt", MetaController, :robots
    get "/manifest.webmanifest", MetaController, :manifest
    get "/api/fortunes", FigureController, :fortunes

    pipe_through :browser

    get "/", GateController, :home
    get "/xin-xam", FigureController, :xin_xam
    get "/giai-nghiep", GiaiNghiepController, :machine
    get "/giai-nghiep/:loai", GiaiNghiepController, :show
    get "/que/:set/:n", ShareController, :show
  end
end
