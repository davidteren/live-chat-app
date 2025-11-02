defmodule LiveChat.ChatTest do
  use LiveChat.DataCase

  alias LiveChat.Chat

  describe "messages" do
    alias LiveChat.Chat.Message

    import LiveChat.ChatFixtures

    @invalid_attrs %{author: nil, content: nil}

    test "list_messages/0 returns all messages" do
      message = message_fixture()
      assert Chat.list_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert Chat.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      valid_attrs = %{author: "some author", content: "some content"}

      assert {:ok, %Message{} = message} = Chat.create_message(valid_attrs)
      assert message.author == "some author"
      assert message.content == "some content"
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Chat.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()
      update_attrs = %{author: "some updated author", content: "some updated content"}

      assert {:ok, %Message{} = message} = Chat.update_message(message, update_attrs)
      assert message.author == "some updated author"
      assert message.content == "some updated content"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_message(message, @invalid_attrs)
      assert message == Chat.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = Chat.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Chat.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = Chat.change_message(message)
    end

    test "list_recent_messages/1 returns recent messages with reactions preloaded" do
      message1 = message_fixture(%{content: "First message"})
      message2 = message_fixture(%{content: "Second message"})
      message3 = message_fixture(%{content: "Third message"})

      messages = Chat.list_recent_messages(10)
      message_ids = Enum.map(messages, & &1.id)

      # All our messages should be in the list
      assert message1.id in message_ids
      assert message2.id in message_ids
      assert message3.id in message_ids

      # Reactions should be preloaded
      assert Enum.all?(messages, fn msg -> Ecto.assoc_loaded?(msg.reactions) end)
    end

    test "list_recent_messages/1 limits the number of messages" do
      for i <- 1..60 do
        message_fixture(%{content: "Message #{i}"})
      end

      messages = Chat.list_recent_messages(50)
      assert length(messages) == 50
    end
  end

  describe "reactions" do
    alias LiveChat.Chat.Reaction

    import LiveChat.ChatFixtures

    test "toggle_reaction/3 adds a reaction when none exists" do
      message = message_fixture()
      user_session_id = "session_123"

      assert {:ok, %Reaction{} = reaction} =
               Chat.toggle_reaction(message.id, user_session_id, "thumbs_up")

      assert reaction.type == "thumbs_up"
      assert reaction.user_session_id == user_session_id
      assert reaction.message_id == message.id
    end

    test "toggle_reaction/3 removes a reaction when it already exists" do
      message = message_fixture()
      user_session_id = "session_123"

      {:ok, _reaction} = Chat.toggle_reaction(message.id, user_session_id, "thumbs_up")
      assert {:ok, %Reaction{}} = Chat.toggle_reaction(message.id, user_session_id, "thumbs_up")

      reactions = Chat.get_message_reactions(message.id)
      assert reactions == []
    end

    test "toggle_reaction/3 switches reaction type" do
      message = message_fixture()
      user_session_id = "session_123"

      {:ok, _reaction} = Chat.toggle_reaction(message.id, user_session_id, "thumbs_up")
      assert {:ok, %Reaction{} = reaction} =
               Chat.toggle_reaction(message.id, user_session_id, "thumbs_down")

      assert reaction.type == "thumbs_down"

      reactions = Chat.get_message_reactions(message.id)
      assert length(reactions) == 1
      assert Enum.at(reactions, 0).type == "thumbs_down"
    end

    test "get_message_reactions/1 returns all reactions for a message" do
      message = message_fixture()

      Chat.toggle_reaction(message.id, "session_1", "thumbs_up")
      Chat.toggle_reaction(message.id, "session_2", "thumbs_up")
      Chat.toggle_reaction(message.id, "session_3", "thumbs_down")

      reactions = Chat.get_message_reactions(message.id)
      assert length(reactions) == 3
    end

    test "count_reactions_by_type/1 returns correct counts" do
      message = message_fixture()

      Chat.toggle_reaction(message.id, "session_1", "thumbs_up")
      Chat.toggle_reaction(message.id, "session_2", "thumbs_up")
      Chat.toggle_reaction(message.id, "session_3", "thumbs_down")
      Chat.toggle_reaction(message.id, "session_4", "heart")

      counts = Chat.count_reactions_by_type(message.id)
      assert counts["thumbs_up"] == 2
      assert counts["thumbs_down"] == 1
      assert counts["heart"] == 1
    end
  end
end
