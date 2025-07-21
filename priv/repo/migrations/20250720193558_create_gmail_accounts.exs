defmodule InboxManager.Repo.Migrations.CreateGmailAccounts do
  use Ecto.Migration

  def change do
    create table(:gmail_accounts) do
      add :email, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :image, :string
      add :token, :string
      add :refresh_token, :string
      add :token_expires_at, :bigint
      add :last_known_history_id, :string
      add :is_active, :boolean, default: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:gmail_accounts, [:email, :user_id])
    create index(:gmail_accounts, [:user_id])
  end
end
