defmodule SorteiosWeb.ExportController do
  use SorteiosWeb, :controller

  def create_qr_code(conn, %{"room_id" => room_id}) do
    invite_image =
      Routes.room_show_url(conn, :show, room_id)
      |> EQRCode.encode()
      |> EQRCode.svg(width: 240)

    conn
    |> put_resp_content_type("image/svg+xml")
    |> put_root_layout(false)
    |> put_resp_header("content-disposition", "attachment; filename=#{room_id}.svg")
    |> send_resp(200, invite_image)
  end
end
