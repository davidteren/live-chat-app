defmodule LiveChatWeb.ChatLive do
  use LiveChatWeb, :live_view

  alias LiveChat.Chat
  alias LiveChatWeb.Presence

  @topic "chat:lobby"

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to chat updates
      Phoenix.PubSub.subscribe(LiveChat.PubSub, @topic)

      # Track user presence
      user_id = generate_user_id()

      {:ok, _} =
        Presence.track(self(), @topic, user_id, %{
          joined_at: :os.system_time(:second)
        })

      # Load recent messages
      messages = Chat.list_recent_messages(50)

      # Get initial presence count
      presence_count = count_presence()

      socket =
        socket
        |> assign(:messages, messages)
        |> assign(:user_id, user_id)
        |> assign(:active_users, presence_count)
        |> assign(:form, to_form(%{"author" => "", "content" => ""}))

      {:ok, socket}
    else
      {:ok,
       assign(socket,
         messages: [],
         user_id: nil,
         active_users: 0,
         form: to_form(%{"author" => "", "content" => ""})
       )}
    end
  end

  @impl true
  def handle_event("send_message", %{"author" => author, "content" => content}, socket) do
    case Chat.create_message(%{author: author, content: content}) do
      {:ok, message} ->
        # Broadcast the new message to all connected clients
        Phoenix.PubSub.broadcast(
          LiveChat.PubSub,
          @topic,
          {:new_message, message}
        )

        # Clear the form
        {:noreply, assign(socket, :form, to_form(%{"author" => author, "content" => ""}))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("toggle_reaction", %{"message_id" => message_id, "type" => type}, socket) do
    message_id = String.to_integer(message_id)

    case Chat.toggle_reaction(message_id, socket.assigns.user_id, type) do
      {:ok, _reaction} ->
        # Broadcast the reaction update
        Phoenix.PubSub.broadcast(
          LiveChat.PubSub,
          @topic,
          {:reaction_updated, message_id}
        )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Reload the message with reactions
    message = Chat.get_message!(message.id) |> LiveChat.Repo.preload(:reactions)

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [message])}
  end

  @impl true
  def handle_info({:reaction_updated, _message_id}, socket) do
    # Reload all messages to get updated reaction counts
    messages = Chat.list_recent_messages(50)

    {:noreply, assign(socket, :messages, messages)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    presence_count = count_presence()
    {:noreply, assign(socket, :active_users, presence_count)}
  end

  # Private functions

  defp generate_user_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end

  defp count_presence do
    Presence.list(@topic) |> map_size()
  end

  # Helper function for counting reactions in the template
  def count_reactions(reactions, type) do
    reactions
    |> Enum.count(fn r -> r.type == type end)
  end
end

