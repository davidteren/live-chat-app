defmodule LiveChatWeb.PageController do
  use LiveChatWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
