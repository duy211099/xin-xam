defmodule ChuaTauWeb.GiaiNghiepFigureTest do
  use ExUnit.Case, async: true

  @path Path.join(:code.priv_dir(:chua_tau), "giai-nghiep/index.html")

  @strings [
    "MÁY GIẢI NGHIỆP",
    "Nhanh · Gọn · Có kết quả",
    "THÂN",
    "KHẨU",
    "Ý",
    "NẶNG",
    "NHÉT TIỀN VÀO ĐÂY",
    "CHỌN NGHIỆP",
    "ĐANG GIẢI...",
    "XONG!",
    "KẾT QUẢ",
    "KHÔNG HOÀN TIỀN",
    "GIẤY CHỨNG NHẬN ĐÃ GIẢI NGHIỆP",
    "Hiệu lực: đến lần sau.",
    "HẾT TIỀN?",
    "Hộp tiền",
    "Máy in kết quả",
    "Búa chuông",
    "Bộ xịt khói",
    "Đèn kệ",
    "Mô-tơ rung kệ",
    "Thanh giữ hàng",
    "Khoảng trống",
    "Lưu giấy",
    "Chia sẻ",
    "← Cổng chùa",
    "ctCertificate"
  ]

  setup_all do
    {:ok, html: File.read!(@path)}
  end

  test "is UTF-8 stored as NFC", %{html: html} do
    assert String.valid?(html)
    assert String.normalize(html, :nfc) == html
  end

  test "contains the owner's exact strings", %{html: html} do
    for s <- @strings do
      assert String.contains?(html, s), "missing #{inspect(s)}"
    end
  end

  test "never calls the output a bill", %{html: html} do
    lower = String.downcase(html)

    for bill <- ["hóa đơn", "hoá đơn"] do
      refute String.contains?(lower, bill), "found #{inspect(bill)}"
    end
  end

  test "exposes the certificate renderer for the share images", %{html: html} do
    assert html =~ ~r/window\.ctCertificate\s*=/
    assert html =~ ~r/\bdraw\(/
  end

  test "has no debug params that skip paying", %{html: html} do
    refute html =~ ~r/q\.(get|has)\(\s*'(receipt|paid|cash)'/
  end

  test "has exactly one </head> and one <title>", %{html: html} do
    assert length(String.split(html, "</head>")) == 2
    assert length(String.split(html, "<title>")) == 2
  end

  test "makes no outside requests", %{html: html} do
    refute html =~ ~r/(src|href)\s*=\s*["']\s*(https?:)?\/\//i
    refute html =~ ~r/url\(\s*["']?(https?:)?\/\//i
    refute html =~ ~r/@import/
    refute html =~ ~r/fetch\(|XMLHttpRequest|WebSocket|sendBeacon|EventSource|\bimport\(/
  end
end
