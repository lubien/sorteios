defmodule SorteiosWeb.RoomLiveTest do
  use SorteiosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sorteios.RoomsFixtures

  alias Sorteios.Rooms

  # ---------------------------------------------------------------------------
  # Session helpers
  # ---------------------------------------------------------------------------

  defp conn_as_admin(conn, room) do
    init_test_session(conn, %{
      "name" => "Admin User",
      "email" => "admin@example.com",
      "admin:#{room.id}" => room.id
    })
  end

  defp conn_as_user(conn) do
    init_test_session(conn, %{
      "name" => "Regular User",
      "email" => "user@example.com"
    })
  end

  # ---------------------------------------------------------------------------
  # Access control
  # ---------------------------------------------------------------------------

  describe "Show - access control" do
    setup do
      %{room: room_fixture()}
    end

    test "redirects when session is missing", %{conn: conn, room: room} do
      assert {:error, {:redirect, %{to: path}}} =
               live(conn, Routes.room_show_path(conn, :show, room))

      assert path =~ "/"
      assert path =~ room.id
    end

    test "displays room id when session is present", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, _lv, html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert html =~ room.id
    end

    test "shows the current user in the participants list", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "Regular User"
    end

    test "admin user is shown in the participants list", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "Admin User"
    end
  end

  # ---------------------------------------------------------------------------
  # Empty state
  # ---------------------------------------------------------------------------

  describe "Show - empty state (no prizes)" do
    setup do
      %{room: room_fixture()}
    end

    test "non-admin sees the waiting message", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "Wait for the admin to create a prize"
    end

    test "non-admin does not see an Add prize button", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      refute has_element?(lv, "button[phx-click='quick_add_prize']")
    end

    test "admin sees Add prize button instead of the waiting message", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert has_element?(lv, "button[phx-click='quick_add_prize']")
    end

    test "admin does not see the waiting message", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      refute render(lv) =~ "Wait for the admin to create a prize"
    end
  end

  # ---------------------------------------------------------------------------
  # quick_add_prize — ordinal naming
  # ---------------------------------------------------------------------------

  describe "Show - quick_add_prize" do
    setup do
      %{room: room_fixture()}
    end

    test "first click creates '1st Prize'", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv |> element("button[phx-click='quick_add_prize']") |> render_click()

      assert render(lv) =~ "1st Prize"
    end

    test "second click creates '2nd Prize'", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv |> element("button[phx-click='quick_add_prize']") |> render_click()
      lv |> element("button[phx-click='quick_add_prize']") |> render_click()

      assert render(lv) =~ "2nd Prize"
    end

    test "third click creates '3rd Prize'", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv |> element("button[phx-click='quick_add_prize']") |> render_click()
      lv |> element("button[phx-click='quick_add_prize']") |> render_click()
      lv |> element("button[phx-click='quick_add_prize']") |> render_click()

      assert render(lv) =~ "3rd Prize"
    end

    test "fourth click creates '4th Prize'", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      for _ <- 1..4 do
        lv |> element("button[phx-click='quick_add_prize']") |> render_click()
      end

      assert render(lv) =~ "4th Prize"
    end

    test "all added prizes appear in the list", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      for _ <- 1..3 do
        lv |> element("button[phx-click='quick_add_prize']") |> render_click()
      end

      html = render(lv)
      assert html =~ "1st Prize"
      assert html =~ "2nd Prize"
      assert html =~ "3rd Prize"
    end

    test "adding a prize removes the empty-state waiting message", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv |> element("button[phx-click='quick_add_prize']") |> render_click()

      refute render(lv) =~ "Wait for the admin to create a prize"
    end

    test "the '+ Add prize' list-header button appears once prizes exist", %{
      conn: conn,
      room: room
    } do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv |> element("button[phx-click='quick_add_prize']") |> render_click()

      assert render(lv) =~ "+ Add prize"
    end
  end

  # ---------------------------------------------------------------------------
  # Prize list rendering
  # ---------------------------------------------------------------------------

  describe "Show - prize list rendering" do
    setup do
      room = room_fixture()
      prize = prize_fixture(room)
      %{room: room, prize: prize}
    end

    test "unclaimed prize name is shown", %{conn: conn, room: room, prize: prize} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ prize.name
    end

    test "unclaimed prize shows 'No winner yet'", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "No winner yet"
    end

    test "claimed prize shows the winner's name", %{conn: conn, room: room} do
      prize_fixture(room, %{
        name: "Claimed Prize",
        winner_name: "Jane Doe",
        winner_email: "jane@example.com"
      })

      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "Jane Doe"
    end

    test "non-admin does not see the winner's email", %{conn: conn, room: room} do
      prize_fixture(room, %{
        name: "Claimed Prize",
        winner_name: "Jane Doe",
        winner_email: "jane@example.com"
      })

      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      refute render(lv) =~ "jane@example.com"
    end

    test "admin sees the winner's email on a claimed prize", %{conn: conn, room: room} do
      prize_fixture(room, %{
        name: "Claimed Prize",
        winner_name: "Jane Doe",
        winner_email: "jane@example.com"
      })

      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert render(lv) =~ "jane@example.com"
    end

    test "admin sees the delete button for an unclaimed prize", %{conn: conn, room: room} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      assert has_element?(lv, "button[phx-click='remove_prize']")
    end

    test "admin does not see the delete button for a claimed prize", %{
      conn: conn,
      room: room,
      prize: prize
    } do
      {:ok, _} =
        Rooms.update_prize(prize, %{winner_name: "Jane Doe", winner_email: "jane@example.com"})

      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      refute has_element?(lv, "button[phx-click='remove_prize']")
    end

    test "non-admin does not see the delete button", %{conn: conn, room: room} do
      conn = conn_as_user(conn)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))
      refute has_element?(lv, "button[phx-click='remove_prize']")
    end
  end

  # ---------------------------------------------------------------------------
  # remove_prize
  # ---------------------------------------------------------------------------

  describe "Show - remove_prize" do
    setup do
      room = room_fixture()
      prize = prize_fixture(room)
      %{room: room, prize: prize}
    end

    test "admin can remove an unclaimed prize", %{conn: conn, room: room, prize: prize} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv
      |> element("button[phx-click='remove_prize'][phx-value-prize-name='#{prize.name}']")
      |> render_click()

      refute render(lv) =~ prize.name
    end

    test "removing the last prize shows the admin empty-state button again", %{
      conn: conn,
      room: room,
      prize: prize
    } do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv
      |> element("button[phx-click='remove_prize'][phx-value-prize-name='#{prize.name}']")
      |> render_click()

      assert has_element?(lv, "button[phx-click='quick_add_prize']")
    end

    test "only the targeted prize is removed when multiple prizes exist", %{
      conn: conn,
      room: room,
      prize: prize
    } do
      other = prize_fixture(room, %{name: "Other Prize"})

      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv
      |> element("button[phx-click='remove_prize'][phx-value-prize-name='#{prize.name}']")
      |> render_click()

      html = render(lv)
      refute html =~ prize.name
      assert html =~ other.name
    end

    test "removing a prize shows a success flash", %{conn: conn, room: room, prize: prize} do
      conn = conn_as_admin(conn, room)
      {:ok, lv, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      lv
      |> element("button[phx-click='remove_prize'][phx-value-prize-name='#{prize.name}']")
      |> render_click()

      assert render(lv) =~ "Prize removed successfully"
    end
  end
end
