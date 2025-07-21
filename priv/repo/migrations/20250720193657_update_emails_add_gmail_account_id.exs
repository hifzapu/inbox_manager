defmodule InboxManager.Repo.Migrations.UpdateEmailsAddGmailAccountId do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :gmail_account_id, references(:gmail_accounts, on_delete: :delete_all)
    end

    create index(:emails, [:gmail_account_id])
  end
end
