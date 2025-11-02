defmodule LiveChat.Repo.Migrations.CreateReactions do
  use Ecto.Migration

  def change do
    create table(:reactions) do
      add :type, :string
      add :user_session_id, :string
      add :message_id, references(:messages, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:reactions, [:message_id])
    create unique_index(:reactions, [:message_id, :user_session_id, :type])
  end
end
