defmodule InboxManager.AccountContext do
  alias InboxManager.User
  alias InboxManager.Repo

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_by_email(email, attrs) do
    user = Repo.get_by(User, email: email)

    if user do
      update_user(user, attrs)
    else
      {:error, "User not found"}
    end
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
