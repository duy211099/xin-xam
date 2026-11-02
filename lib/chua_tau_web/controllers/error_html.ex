defmodule ChuaTauWeb.ErrorHTML do
  @moduledoc "Vietnamese 404 and 500 pages, rendered by the endpoint and by `ShareController`."
  use ChuaTauWeb, :html

  embed_templates "error_html/*"
end
