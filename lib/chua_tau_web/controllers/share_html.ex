defmodule ChuaTauWeb.ShareHTML do
  use ChuaTauWeb, :html

  embed_templates "share_html/*"

  def category_label("good"), do: "Quẻ tốt"
  def category_label("neutral"), do: "Quẻ bình"
  def category_label("bad"), do: "Quẻ xấu"
  def category_label(other), do: other
end
