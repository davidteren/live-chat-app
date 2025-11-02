defmodule LiveChat.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias LiveChat.Repo

  alias LiveChat.Chat.Message
  alias LiveChat.Chat.Reaction

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  @doc """
  Returns the list of recent messages with reactions preloaded.

  ## Examples

      iex> list_recent_messages(50)
      [%Message{}, ...]

  """
  def list_recent_messages(limit \\ 50) do
    Message
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload(:reactions)
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{data: %Message{}}

  """
  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end

  # Reaction functions

  @doc """
  Toggles a reaction for a message.
  If the user already has this reaction type, it removes it.
  If the user has a different reaction type, it switches to the new type.
  If the user has no reaction, it adds the new reaction.

  ## Examples

      iex> toggle_reaction(1, "session_123", "thumbs_up")
      {:ok, %Reaction{}}

  """
  def toggle_reaction(message_id, user_session_id, type) do
    existing_reaction =
      Repo.get_by(Reaction, message_id: message_id, user_session_id: user_session_id, type: type)

    case existing_reaction do
      nil ->
        # Remove any other reaction type from this user for this message
        Repo.delete_all(
          from r in Reaction,
            where: r.message_id == ^message_id and r.user_session_id == ^user_session_id
        )

        # Add the new reaction
        %Reaction{}
        |> Reaction.changeset(%{
          message_id: message_id,
          user_session_id: user_session_id,
          type: type
        })
        |> Repo.insert()

      reaction ->
        # Remove the existing reaction
        Repo.delete(reaction)
    end
  end

  @doc """
  Gets all reactions for a message.

  ## Examples

      iex> get_message_reactions(1)
      [%Reaction{}, ...]

  """
  def get_message_reactions(message_id) do
    Repo.all(from r in Reaction, where: r.message_id == ^message_id)
  end

  @doc """
  Counts reactions by type for a message.

  ## Examples

      iex> count_reactions_by_type(1)
      %{"thumbs_up" => 5, "thumbs_down" => 2}

  """
  def count_reactions_by_type(message_id) do
    Repo.all(
      from r in Reaction,
        where: r.message_id == ^message_id,
        group_by: r.type,
        select: {r.type, count(r.id)}
    )
    |> Enum.into(%{})
  end
end
