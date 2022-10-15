defmodule SorteiosWeb.PageController do
  use SorteiosWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
