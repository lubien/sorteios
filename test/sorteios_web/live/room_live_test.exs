defmodule SorteiosWeb.RoomLiveTest do
  use SorteiosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Sorteios.RoomsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_room(_) do
    room = room_fixture()
    %{room: room}
  end

  describe "Index" do
    setup [:create_room]

    test "lists all rooms", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.room_index_path(conn, :index))

      assert html =~ "Listing Rooms"
    end

    test "saves new room", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

      assert index_live |> element("a", "New Room") |> render_click() =~
               "New Room"

      assert_patch(index_live, Routes.room_index_path(conn, :new))

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#room-form", room: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.room_index_path(conn, :index))

      assert html =~ "Room created successfully"
    end

    test "updates room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

      assert index_live |> element("#room-#{room.id} a", "Edit") |> render_click() =~
               "Edit Room"

      assert_patch(index_live, Routes.room_index_path(conn, :edit, room))

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#room-form", room: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.room_index_path(conn, :index))

      assert html =~ "Room updated successfully"
    end

    test "deletes room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

      assert index_live |> element("#room-#{room.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#room-#{room.id}")
    end
  end

  describe "Show" do
    setup [:create_room]

    test "displays room", %{conn: conn, room: room} do
      {:ok, _show_live, html} = live(conn, Routes.room_show_path(conn, :show, room))

      assert html =~ "Show Room"
    end

    test "updates room within modal", %{conn: conn, room: room} do
      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Room"

      assert_patch(show_live, Routes.room_show_path(conn, :edit, room))

      assert show_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#room-form", room: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.room_show_path(conn, :show, room))

      assert html =~ "Room updated successfully"
    end
  end
end
