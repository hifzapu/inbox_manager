defmodule InboxManager.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :first_name, :string
      add :last_name, :string
      add :location, :string
      add :image, :string
      add :provider, :string
      add :token, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
