defmodule LiveChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :author, :string
    field :content, :string

    has_many :reactions, LiveChat.Chat.Reaction

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :author])
    |> validate_required([:content, :author])
  end
end
