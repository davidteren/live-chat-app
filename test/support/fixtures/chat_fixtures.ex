defmodule LiveChat.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveChat.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        author: "some author",
        content: "some content"
      })
      |> LiveChat.Chat.create_message()

    message
  end
end
