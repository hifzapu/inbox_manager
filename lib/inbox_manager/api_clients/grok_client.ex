defmodule InboxManager.ApiClients.GroqClient do
  @moduledoc """
  Client for the Groq API.
  """

  def categorize_with_groq(prompt) do
    url = "https://api.groq.com/openai/v1/chat/completions"

    headers = [
      {"Authorization", "Bearer #{Application.get_env(:inbox_manager, :deepseek_api_key)}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      "model" => "llama-3.1-8b-instant",
      "messages" => [
        %{
          "role" => "system",
          "content" =>
            "You are an email categorization assistant. Return only the category name, nothing else."
        },
        %{
          "role" => "user",
          "content" => prompt
        }
      ],
      "temperature" => 0.1,
      "max_tokens" => 50
    }

    case HTTPoison.post(url, Jason.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        response = Jason.decode!(response_body)

        response["choices"]
        |> List.first()
        |> get_in(["message", "content"])
        |> String.trim()

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        IO.inspect("Groq API Error - Status: #{status}, Body: #{body}")
        "Uncategorized"

      {:error, reason} ->
        IO.inspect("Groq Request Error: #{inspect(reason)}")
        "Uncategorized"
    end
  end
end
