defmodule InboxManager.Auth.TokenRefresher do
  @moduledoc """
  Module for refreshing OAuth tokens using Ueberauth Google
  """

  alias InboxManager.Repo
  alias InboxManager.Users.User
  require Logger

  @google_token_url "https://oauth2.googleapis.com/token"

  @doc """
  Ensures the user has a valid access token, refreshing if necessary
  """
  def ensure_valid_token(%User{} = user) do
    if token_expired?(user) do
      refresh_token(user)
    else
      {:ok, user}
    end
  end

  @doc """
  Check if the token is expired or about to expire (within 5 minutes)
  """
  def token_expired?(%User{token_expires_at: nil}), do: true

  def token_expired?(%User{token_expires_at: expires_at}) do
    # Check if token expires within 5 minutes
    # 5 minutes in seconds
    buffer_time = 5 * 60

    # Convert Unix timestamp to DateTime
    expires_datetime = DateTime.from_unix!(expires_at)
    buffer_datetime = DateTime.add(expires_datetime, -buffer_time, :second)

    DateTime.compare(DateTime.utc_now(), buffer_datetime) != :lt
  end

  @doc """
  Refresh the user's access token using their refresh token
  """
  def refresh_token(%User{refresh_token: nil} = user) do
    Logger.error("No refresh token available for user #{user.email}")
    {:error, :no_refresh_token}
  end

  def refresh_token(%User{refresh_token: refresh_token} = user) do
    params = %{
      "client_id" => google_client_id(),
      "client_secret" => google_client_secret(),
      "refresh_token" => refresh_token,
      "grant_type" => "refresh_token"
    }

    case HTTPoison.post(@google_token_url, Jason.encode!(params), [
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        handle_refresh_response(user, body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Token refresh failed with status #{status_code}: #{body}")
        {:error, :refresh_failed}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP error during token refresh: #{reason}")
        {:error, :http_error}
    end
  end

  defp handle_refresh_response(user, body) do
    case Jason.decode(body) do
      {:ok, %{"access_token" => new_token, "expires_in" => expires_in}} ->
        expires_at = DateTime.add(DateTime.utc_now(), expires_in, :second)
        expires_timestamp = DateTime.to_unix(expires_at)

        update_attrs = %{
          token: new_token,
          token_expires_at: expires_timestamp
        }

        case Repo.update(User.changeset(user, update_attrs)) do
          {:ok, updated_user} ->
            Logger.info("Successfully refreshed token for user #{user.email}")
            {:ok, updated_user}

          {:error, changeset} ->
            Logger.error("Failed to update user with new token: #{inspect(changeset.errors)}")
            {:error, :update_failed}
        end

      {:ok, %{"error" => error}} ->
        Logger.error("Token refresh error: #{error}")
        {:error, :refresh_error}

      {:error, _} ->
        Logger.error("Invalid JSON response from token refresh")
        {:error, :invalid_response}
    end
  end

  defp google_client_id do
    Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)[:client_id]
  end

  defp google_client_secret do
    Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)[:client_secret]
  end
end
