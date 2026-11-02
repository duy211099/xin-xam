defmodule ChuaTauWeb.Machines do
  @moduledoc """
  The machines standing in the gate scene, in display order.

  `scene` is the machine's foot point as a percentage of the scene box
  (x across, y down). `thumb_size` is the PNG's pixel size, written by
  `scripts/capture-machines`.
  """

  @enforce_keys [:slug, :name, :tagline, :thumb, :thumb_size, :accent, :scene]
  defstruct [:slug, :name, :tagline, :thumb, :thumb_size, :accent, :scene]

  @type t :: %__MODULE__{
          slug: String.t(),
          name: String.t(),
          tagline: String.t(),
          thumb: String.t(),
          thumb_size: {pos_integer, pos_integer},
          accent: String.t(),
          scene: {number, number}
        }

  defp machines do
    [
      %__MODULE__{
        slug: "xin-xam",
        name: "Xin xăm",
        tagline: "Thành tâm khấn nguyện, bỏ đồng xu, nhận quẻ.",
        thumb: "/images/machines/xin-xam.png",
        thumb_size: {347, 520},
        scene: {27, 62},
        accent: "#d6a53a"
      },
      %__MODULE__{
        slug: "giai-nghiep",
        name: "Giải nghiệp",
        tagline: "Nhanh · Gọn · Có kết quả",
        thumb: "/images/machines/giai-nghiep.png",
        thumb_size: {257, 520},
        scene: {73, 62},
        accent: "#e5533d"
      }
    ]
  end

  @spec all() :: [t]
  def all, do: machines()

  @spec path(t) :: String.t()
  def path(%__MODULE__{slug: slug}), do: "/" <> slug
end
