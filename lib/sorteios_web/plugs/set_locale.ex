defmodule SorteiosWeb.Plugs.SetLocale do
  @moduledoc """
  Selects the request locale from the query, session, or browser preferences.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_query_params(conn)

    locale =
      conn
      |> requested_locale()
      |> normalize()

    Gettext.put_locale(SorteiosWeb.Gettext, locale)

    conn
    |> put_session("locale", locale)
    |> assign(:locale, locale)
  end

  def known_locales, do: Gettext.known_locales(SorteiosWeb.Gettext)

  def normalize(locale) when is_binary(locale) do
    case String.downcase(locale) do
      "pt" -> "pt_BR"
      "pt-br" -> "pt_BR"
      "pt_br" -> "pt_BR"
      "en" -> "en"
      _ -> "en"
    end
  end

  def normalize(_locale), do: "en"

  defp requested_locale(conn) do
    conn.params["locale"] ||
      get_session(conn, "locale") ||
      conn |> get_req_header("accept-language") |> List.first() |> browser_locale()
  end

  defp browser_locale(nil), do: "en"

  defp browser_locale(header) do
    header
    |> String.split(",")
    |> Enum.map(&parse_language_range/1)
    |> Enum.sort_by(fn {_locale, quality} -> quality end, :desc)
    |> Enum.find_value("en", fn {locale, quality} ->
      if quality > 0, do: browser_locale_to_app(locale)
    end)
  end

  defp parse_language_range(value) do
    [locale | params] = String.split(value, ";")

    quality =
      params
      |> Enum.find_value(1.0, fn param ->
        case String.split(String.trim(param), "=", parts: 2) do
          ["q", value] -> parse_quality(value)
          _ -> nil
        end
      end)

    {String.trim(locale), quality}
  end

  defp parse_quality(value) do
    case Float.parse(value) do
      {quality, ""} -> quality
      _ -> 0.0
    end
  end

  defp browser_locale_to_app(locale) do
    case String.downcase(locale) do
      "pt" -> "pt_BR"
      "pt-br" -> "pt_BR"
      "en" -> "en"
      _ -> nil
    end
  end
end
