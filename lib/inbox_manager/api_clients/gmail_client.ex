defmodule InboxManager.ApiClients.GmailClient do
  @gmail_api_url "https://gmail.googleapis.com/gmail/v1/users"

  # Set up Gmail push notifications for real-time email alerts

  def get_message_details(access_token, message_id, user_email \\ "me") do
    url = "#{@gmail_api_url}/#{user_email}/messages/#{message_id}"

    headers = build_headers(access_token)

    case HTTPoison.get(url, headers) do
      {:ok, %{body: body}} ->
        Jason.decode(body)

      {:error, error} ->
        {:error, error}
    end
  end

  def setup_push_notifications(access_token, user_email \\ "me") do
    url = "#{@gmail_api_url}/#{user_email}/watch"

    headers = build_headers(access_token)

    body =
      Jason.encode!(%{
        topicName: "projects/eco-limiter-426419-e6/topics/gmail-notifications",
        labelIds: ["INBOX"],
        labelFilterAction: "include"
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"historyId" => history_id} = response} ->
            InboxManager.AccountContext.update_user_by_email(user_email, %{
              last_known_history_id: history_id
            })

            {:ok, response}

          {:ok, response} ->
            {:ok, response}

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # Stop push notifications
  def stop_push_notifications(access_token, user_email \\ "me") do
    url = "#{@gmail_api_url}/#{user_email}/stop"

    headers = build_headers(access_token)

    case HTTPoison.post(url, "", headers) do
      {:ok, _response} ->
        {:ok, "Push notifications stopped"}

      {:error, error} ->
        {:error, error}
    end
  end

  # Get history changes since a specific history ID
  def get_history_changes(access_token, history_id, user_email \\ "me") do
    base_url = "#{@gmail_api_url}/#{user_email}/history"

    # Build query parameters manually to handle labelIds properly
    query_params =
      URI.encode_query(%{
        "startHistoryId" => history_id,
        "historyTypes" => "messageAdded",
        "labelIds" => "INBOX"
      })

    url = "#{base_url}?#{query_params}"

    headers = build_headers(access_token)

    case HTTPoison.get(url, headers) do
      {:ok, %{body: body}} ->
        Jason.decode(body)

      {:error, error} ->
        {:error, error}
    end
  end

  # Get messages that were added since a specific history ID
  def get_messages_since_history(access_token, history_id, user_email \\ "me") do
    case get_history_changes(access_token, history_id, user_email) do
      {:ok, %{"history" => history_list}} ->
        message_ids =
          history_list
          |> Enum.flat_map(fn history ->
            history["messagesAdded"] || []
          end)
          |> Enum.map(fn message ->
            message["message"]["id"]
          end)
          |> Enum.uniq()

        # Filter to only include messages that are in the INBOX (received emails)
        filtered_message_ids = filter_incoming_messages(access_token, message_ids, user_email)
        {:ok, filtered_message_ids}

      {:ok, _} ->
        {:ok, []}

      {:error, error} ->
        {:error, error}
    end
  end

  # Get only incoming messages since a specific history ID
  def get_incoming_messages_since_history(access_token, history_id, user_email \\ "me") do
    get_messages_since_history(access_token, history_id, user_email)
  end

  # Filter messages to only include those in the INBOX (received emails)
  defp filter_incoming_messages(access_token, message_ids, user_email) do
    message_ids
    |> Enum.filter(fn message_id ->
      case get_message_details(access_token, message_id, user_email) do
        {:ok, %{"labelIds" => label_ids}} ->
          # Only include messages that have the INBOX label (received emails)
          "INBOX" in label_ids

        _ ->
          false
      end
    end)
  end

  defp build_headers(access_token) do
    [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]
  end
end
