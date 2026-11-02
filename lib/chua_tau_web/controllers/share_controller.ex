defmodule ChuaTauWeb.ShareController do
  use ChuaTauWeb, :controller

  alias ChuaTau.Fortunes
  alias ChuaTauWeb.Seo

  plug :put_root_layout, html: {ChuaTauWeb.Layouts, :root}
  plug :put_layout, false

  def show(conn, %{"set" => set, "n" => n}) do
    with collection when not is_nil(collection) <- Fortunes.get(set),
         {number, ""} <- Integer.parse(n),
         fortune when not is_nil(fortune) <- Fortunes.fortune(collection, number) do
      render(conn, :show,
        collection: collection,
        fortune: fortune,
        seo: share_seo(collection, fortune),
        stylesheet: "/css/share.css"
      )
    else
      _ -> not_found(conn)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_root_layout(false)
    |> put_view(html: ChuaTauWeb.ErrorHTML)
    |> render("404.html")
  end

  defp share_seo(collection, fortune) do
    %Seo{
      title: "Quẻ số #{fortune.number} · #{collection.name} · Máy xin xăm online",
      description:
        "Quẻ số #{fortune.number}/#{collection.total} trong bộ #{collection.name}: #{String.replace_prefix(fortune.title, "(mẫu) ", "")}. Đọc lời thơ, lời giải và lời khuyên, hoặc tự xin một quẻ ở máy xin xăm online.",
      url: Seo.absolute("/que/#{collection.id}/#{fortune.number}"),
      noindex: fortune.sample
    }
  end
end
