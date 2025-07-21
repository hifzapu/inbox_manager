defmodule InboxManagerWeb.GmailWebhookControllerTest do
  use InboxManagerWeb.ConnCase

  test "POST /webhooks/gmail with missing message data returns error", %{conn: conn} do
    conn = post(conn, "/webhooks/gmail", %{})
    assert json_response(conn, 400)["error"] == "Missing message data"
  end

  test "POST /webhooks/gmail with invalid base64 returns error", %{conn: conn} do
    conn = post(conn, "/webhooks/gmail", %{message: %{"data" => "not_base64"}})
    assert json_response(conn, 400)["error"] == "Invalid base64 data"
  end
end
