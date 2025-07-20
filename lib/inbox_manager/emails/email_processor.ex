defmodule InboxManager.Emails.EmailProcessor do
  @moduledoc """
  Service for processing new emails, categorizing them with AI, and storing them.
  """

  alias InboxManager.ApiClients.GmailClient
  alias InboxManager.ApiClients.GroqClient
  alias InboxManager.Repo
  alias InboxManager.Categories.Category
  alias InboxManager.Emails
  alias InboxManager.Categories

  def process_new_email(access_token, message_id, user) do
    # Get the full message details from Gmail
    case GmailClient.get_message_details(access_token, message_id, user.email) do
      {:ok, message_data} ->
        # Extract email content and metadata
        email_data = extract_email_data(message_data)

        # Categorize the email using AI
        category = categorize_email_with_ai(email_data, user.id)

        # Store the email in the database
        store_email(email_data, category, user.id)

        {:ok, email_data}

      {:error, error} ->
        {:error, "Failed to fetch message details: #{error}"}
    end
  end

  defp extract_email_data(message_data) do
    # Extract headers
    headers = message_data["payload"]["headers"] || []

    subject = get_header_value(headers, "Subject") || "No Subject"
    from = get_header_value(headers, "From") || "Unknown"
    to = get_header_value(headers, "To") || ""
    date = get_header_value(headers, "Date") || ""

    # Extract body content
    body = extract_body_content(message_data["payload"])

    %{
      gmail_id: message_data["id"],
      subject: subject,
      from: from,
      to: to,
      date: date,
      body: body,
      snippet: message_data["snippet"] || "",
      thread_id: message_data["threadId"]
    }
  end

  defp get_header_value(headers, name) do
    headers
    |> Enum.find(fn header -> header["name"] == name end)
    |> case do
      nil -> nil
      header -> header["value"]
    end
  end

  defp extract_body_content(payload) do
    case payload do
      %{"body" => %{"data" => data}} when is_binary(data) ->
        case data
             |> String.replace("-", "+")
             |> String.replace("_", "/")
             |> Base.decode64() do
          {:ok, decoded} -> decoded
          :error -> ""
        end

      %{"parts" => parts} when is_list(parts) ->
        parts
        |> Enum.find(fn part ->
          part["mimeType"] == "text/plain" || part["mimeType"] == "text/html"
        end)
        |> case do
          nil -> ""
          part -> extract_body_content(part)
        end

      _ ->
        ""
    end
  end

  def categorize_email_with_ai(email_data, user_id) do
    # Get all categories from the database
    categories = Categories.list_categories(user_id)

    # Create a prompt for AI categorization
    prompt = create_categorization_prompt(email_data, categories)

    case GroqClient.categorize_with_groq(prompt) do
      category_name ->
        # Find the category by name
        case Enum.find(categories, fn category -> category.name == category_name end) do
          nil ->
            # If no category found, create a new "Other" category
            create_or_find_other_category(user_id)

          category ->
            category
        end
    end
  end

  defp create_categorization_prompt(email_data, categories) do
    category_descriptions =
      categories
      |> Enum.map(fn cat -> "- #{cat.name}: #{cat.description}" end)
      |> Enum.join("\n")

    """
    Please categorize the following email into one of these categories:

    #{category_descriptions}

    Email Subject: #{email_data.subject}
    Email From: #{email_data.from}
    Email Body: #{email_data.body}

    Return only the category name that best fits this email.
    """
  end

  defp create_or_find_other_category(user_id) do
    # Try to find existing "Other" category first
    case Categories.get_category_by_name("Other", user_id) do
      nil ->
        # Create new "Other" category if it doesn't exist
        Categories.create_category(%{
          name: "Other",
          description: "Miscellaneous emails that don't fit other categories",
          user_id: user_id
        })

      category ->
        category
    end
  end

  defp store_email(email_data, category, user_id) do
    # Create the email record using the Emails context
    email_params = %{
      gmail_id: email_data.gmail_id,
      subject: email_data.subject,
      from: email_data.from,
      to: email_data.to,
      body: email_data.body,
      snippet: email_data.snippet,
      thread_id: email_data.thread_id,
      date: email_data.date,
      category_id: if(category, do: category.id, else: nil),
      user_id: user_id
    }

    Emails.create_email(email_params)
  end
end
