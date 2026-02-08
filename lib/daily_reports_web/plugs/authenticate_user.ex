defmodule DailyReportsWeb.Plugs.AuthenticateUser do
  @moduledoc """
  Plug to authenticate users via JWT tokens from cookies.

  This plug looks for an access token in the request cookies,
  verifies it, and assigns the current user to the connection.

  ## Options
    - :required - Boolean, whether authentication is required (default: true)
      If true, returns 401 if no valid token is found
      If false, continues without assigning current_user

  ## Usage

      # In router - require authentication
      plug DailyReportsWeb.Plugs.AuthenticateUser

      # In router - optional authentication
      plug DailyReportsWeb.Plugs.AuthenticateUser, required: false

  ## Assigns
    - :current_user - The authenticated user struct
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias DailyReports.Accounts

  def init(opts), do: opts

  def call(conn, opts) do
    required = Keyword.get(opts, :required, true)
    conn = Plug.Conn.fetch_cookies(conn)

    case get_token_from_cookie(conn) do
      nil ->
        handle_missing_token(conn, required)

      token ->
        case Accounts.verify_token(token) do
          {:ok, user, _claims} ->
            assign(conn, :current_user, user)

          {:error, _reason} ->
            handle_invalid_token(conn, required)
        end
    end
  end

  defp get_token_from_cookie(conn) do
    conn.req_cookies["access_token"]
  end

  defp handle_missing_token(conn, true) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{detail: "Authentication required"}})
    |> halt()
  end

  defp handle_missing_token(conn, false) do
    conn
  end

  defp handle_invalid_token(conn, true) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{detail: "Invalid or expired token"}})
    |> halt()
  end

  defp handle_invalid_token(conn, false) do
    conn
  end
end
