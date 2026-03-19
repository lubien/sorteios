defmodule SorteiosWeb.RoomLiveTest do
  use SorteiosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sorteios.RoomsFixtures

  defp create_room(_) do
    room = room_fixture()
    %{room: room}
  end

  defp conn_with_session(conn, name, email) do
    conn
    |> init_test_session(%{"name" => name, "email" => email})
  end

  describe "Show" do
    setup [:create_room]

    test "redirects to home when session is missing", %{conn: conn, room: room} do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, Routes.room_show_path(conn, :show, room))

      assert path =~ "/"
      assert path =~ room.id
    end

    test "displays room when session is present", %{conn: conn, room: room} do
      conn = conn_with_session(conn, "Test User", "test@example.com")

      {:ok, _show_live, html} = live(conn, Routes.room_show_path(conn, :show, room))

      assert html =~ room.id
    end

    test "shows participants list", %{conn: conn, room: room} do
      conn = conn_with_session(conn, "Alice", "alice@example.com")

      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      assert render(show_live) =~ "Alice"
    end

    test "admin flag is set when session marks room admin", %{conn: conn, room: room} do
      conn =
        conn
        |> init_test_session(%{
          "name" => "Admin User",
          "email" => "admin@example.com",
          "admin:#{room.id}" => room.id
        })

      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      assert render(show_live) =~ "Admin User"
    end
  end
end
