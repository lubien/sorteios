defmodule SorteiosWeb.Plugs.SetLocaleTest do
  use ExUnit.Case, async: true

  import Plug.Conn

  alias SorteiosWeb.Plugs.SetLocale

  test "normalizes supported locale aliases" do
    assert SetLocale.normalize("pt-BR") == "pt_BR"
    assert SetLocale.normalize("pt") == "pt_BR"
    assert SetLocale.normalize("en-US") == "en"
    assert SetLocale.normalize("fr") == "en"
  end

  test "prefers query locale over session and browser locale" do
    conn =
      :get
      |> Plug.Test.conn("/?locale=en")
      |> Plug.Test.init_test_session(%{"locale" => "pt_BR"})
      |> put_req_header("accept-language", "pt-BR")
      |> SetLocale.call([])

    assert conn.assigns.locale == "en"
    assert get_session(conn, "locale") == "en"
  end

  test "uses browser locale when query and session are absent" do
    conn =
      :get
      |> Plug.Test.conn("/")
      |> Plug.Test.init_test_session(%{})
      |> put_req_header("accept-language", "pt-BR,pt;q=0.9")
      |> SetLocale.call([])

    assert conn.assigns.locale == "pt_BR"
  end

  test "uses the highest quality supported browser locale" do
    conn =
      :get
      |> Plug.Test.conn("/")
      |> Plug.Test.init_test_session(%{})
      |> put_req_header("accept-language", "pt-BR;q=1.0,en;q=0.8")
      |> SetLocale.call([])

    assert conn.assigns.locale == "pt_BR"
  end

  test "falls back to English without a locale hint" do
    conn = :get |> Plug.Test.conn("/") |> Plug.Test.init_test_session(%{}) |> SetLocale.call([])

    assert conn.assigns.locale == "en"
  end
end
