defmodule ChuaTauWeb.Machines do
  @moduledoc "The machines listed on the gate page, in display order."

  @enforce_keys [:slug, :name, :tagline, :thumb, :accent]
  defstruct [:slug, :name, :tagline, :thumb, :accent]

  @type t :: %__MODULE__{
          slug: String.t(),
          name: String.t(),
          tagline: String.t(),
          thumb: String.t(),
          accent: String.t()
        }

  defp machines do
    [
      %__MODULE__{
        slug: "xin-xam",
        name: "Xin xăm",
        tagline: "Thành tâm khấn nguyện, bỏ đồng xu, nhận quẻ.",
        thumb: "/images/machines/xin-xam.png",
        accent: "#d6a53a"
      },
      %__MODULE__{
        slug: "giai-nghiep",
        name: "Giải nghiệp",
        tagline: "Nhanh · Gọn · Có hóa đơn",
        thumb: "/images/machines/giai-nghiep.png",
        accent: "#e5533d"
      }
    ]
  end

  @spec all() :: [t]
  def all, do: machines()

  @spec path(t) :: String.t()
  def path(%__MODULE__{slug: slug}), do: "/" <> slug
end
