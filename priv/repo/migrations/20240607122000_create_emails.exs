defmodule InboxManager.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :gmail_id, :string, null: false
      add :subject, :string, null: false
      add :from, :string, null: false
      add :to, :string
      add :body, :text
      add :snippet, :text
      add :thread_id, :string
      add :date, :string
      add :category_id, references(:categories, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:emails, [:gmail_id])
    create index(:emails, [:category_id])
    create index(:emails, [:thread_id])
  end
end
