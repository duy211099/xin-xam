defmodule ChuaTau.Fortunes.Sample do
  @moduledoc """
  Deterministic placeholder text for numbers that have no written fortune.
  The pools and the entry shape mirror the original browser-side generator.
  """

  import Bitwise

  alias ChuaTau.Fortune

  @titles [
    "Trăng soi giếng cổ",
    "Thuyền về bến cũ",
    "Mai nở trong sương",
    "Khói hương lên thẳng",
    "Chuông chiều vọng xa",
    "Gió lặng rừng thông",
    "Đèn thắp sớm",
    "Mưa xuân thấm đất"
  ]

  @verses [
    ["Gió lay cành trúc nghiêng nghiêng,", "Gốc sâu vẫn giữ đất xưa chẳng rời."],
    ["Đèn khuya thắp sớm chẳng thừa,", "Đêm dài có lửa, sớm trưa có đường."],
    ["Sông êm thuyền chậm qua cầu,", "Rồi ra cũng tới bến sau bến chờ."],
    ["Cành mai sương phủ lơ thơ,", "Xuân về hoa vẫn đúng giờ mà khai."],
    ["Khói hương lặng gió không phai,", "Lòng thành một nén, việc dài hóa ngắn."],
    ["Đá kề đá, bước chân yên,", "Cầu xây từng nhịp, chẳng phiền mà xong."]
  ]

  @readings [
    "Việc chậm nhưng đi đúng hướng.",
    "Điều đang lo nhỏ hơn mình nghĩ.",
    "Có người thân bên cạnh giúp đỡ.",
    "Làm xong việc cũ rồi hãy bắt đầu việc mới.",
    "Kiên nhẫn hôm nay, đỡ vất vả mai sau.",
    "Câu trả lời rõ ràng sẽ đến sau một thời gian chờ."
  ]

  @advices [
    "Giữ nếp sinh hoạt điều độ trong tuần này.",
    "Bàn bạc với gia đình trước khi quyết định.",
    "Rộng rãi thời gian, cẩn trọng tiền bạc.",
    "Chờ dấu hiệu rõ hơn rồi hãy đi xa.",
    "Sửa cái cũ trước khi mua cái mới.",
    "Viết kế hoạch ra giấy và làm theo."
  ]

  @categories ~w(good good neutral neutral neutral bad)

  @spec entry(String.t(), pos_integer()) :: Fortune.t()
  def entry(collection_id, number) do
    h = :erlang.phash2({collection_id, number}, 4_294_967_296)
    [v1, v2] = [pick(@verses, h, 3), pick(@verses, h, 9)]

    %Fortune{
      number: number,
      title: "(mẫu) " <> pick(@titles, h, 0),
      category: pick(@categories, h, 15),
      poem: v1 ++ v2,
      interpretation: "(mẫu) " <> pick(@readings, h, 5),
      advice: "(mẫu) " <> pick(@advices, h, 11),
      sample: true,
      generated: true
    }
  end

  defp pick(pool, h, shift), do: Enum.at(pool, rem(h >>> shift, length(pool)))
end
