defmodule InboxManager.Emails.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emails" do
    field :gmail_id, :string
    field :subject, :string
    field :from, :string
    field :to, :string
    field :body, :string
    field :snippet, :string
    field :thread_id, :string
    field :date, :string
    field :description, :string
    belongs_to :category, InboxManager.Categories.Category
    belongs_to :user, InboxManager.Users.User

    timestamps()
  end

  @doc false
  def changeset(email, attrs) do
    email
    |> cast(attrs, [
      :gmail_id,
      :subject,
      :from,
      :to,
      :body,
      :snippet,
      :thread_id,
      :date,
      :category_id,
      :user_id,
      :description
    ])
    |> validate_required([:gmail_id, :subject, :from, :user_id])
    |> unique_constraint(:gmail_id)
    |> foreign_key_constraint(:user_id)
  end
end
