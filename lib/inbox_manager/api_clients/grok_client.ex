defmodule InboxManager.ApiClients.GroqClient do
  @moduledoc """
  Client for the Groq API.
  """

  def categorize_with_groq(prompt) do
    make_groq_request(
      prompt,
      "You are an email categorization assistant. Return only the category name, nothing else.",
      0.1,
      50,
      "Uncategorized"
    )
  end

  def generate_description_with_groq(prompt) do
    make_groq_request(
      prompt,
      "You are an email analysis assistant. Provide clear, descriptive explanations of email content in 10-15 words. Focus on the main purpose and key points of the email.",
      0.3,
      100,
      "Email description unavailable"
    )
  end

  defp make_groq_request(prompt, system_message, temperature, max_tokens, fallback_response) do
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
          "content" => system_message
        },
        %{
          "role" => "user",
          "content" => prompt
        }
      ],
      "temperature" => temperature,
      "max_tokens" => max_tokens
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
        fallback_response

      {:error, reason} ->
        IO.inspect("Groq Request Error: #{inspect(reason)}")
        fallback_response
    end
  end
end
