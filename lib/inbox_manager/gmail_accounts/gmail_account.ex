defmodule InboxManager.GmailAccounts.GmailAccount do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gmail_accounts" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :image, :string
    field :token, :string
    field :refresh_token, :string
    field :token_expires_at, :integer
    field :last_known_history_id, :string
    field :is_active, :boolean, default: true

    belongs_to :user, InboxManager.Users.User
    has_many :emails, InboxManager.Emails.Email

    timestamps()
  end

  @doc false
  def changeset(gmail_account, attrs) do
    gmail_account
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :image,
      :token,
      :refresh_token,
      :token_expires_at,
      :last_known_history_id,
      :is_active,
      :user_id
    ])
    |> validate_required([:email, :user_id])
    |> unique_constraint([:email, :user_id], name: :gmail_accounts_email_user_id_index)
    |> foreign_key_constraint(:user_id)
  end
end
