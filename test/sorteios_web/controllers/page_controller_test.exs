defmodule SorteiosWeb.PageControllerTest do
  use SorteiosWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Sorteios"
  end

  test "locale links preserve invite query parameters", %{conn: conn} do
    html = conn |> get("/?room_id=abc123") |> html_response(200)

    assert html =~ "room_id=abc123"
    assert html =~ "locale=en"
    assert html =~ "locale=pt_BR"
  end
end
