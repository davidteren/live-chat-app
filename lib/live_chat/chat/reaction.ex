defmodule LiveChat.Chat.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "reactions" do
    field :type, :string
    field :user_session_id, :string

    belongs_to :message, LiveChat.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:type, :user_session_id, :message_id])
    |> validate_required([:type, :user_session_id, :message_id])
  end
end
