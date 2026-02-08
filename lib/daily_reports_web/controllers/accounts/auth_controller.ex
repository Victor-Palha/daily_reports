defmodule DailyReportsWeb.Accounts.AuthController do
  use DailyReportsWeb, :controller

  alias DailyReports.Accounts

  action_fallback DailyReportsWeb.FallbackController

  @doc """
  Authenticates a user and returns JWT tokens.

  ## Parameters
    - email: User's email address
    - password: User's password

  ## Response
    - 200: Returns user data and tokens, sets cookies
    - 401: Invalid credentials
  """
  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        case Accounts.generate_tokens(user) do
          {:ok, access_token, refresh_token} ->
            conn
            |> put_http_cookie("access_token", access_token, max_age: 3600)
            |> put_http_cookie("refresh_token", refresh_token, max_age: 2_592_000)
            |> put_status(:ok)
            |> render(:auth, user: user, access_token: access_token, refresh_token: refresh_token)

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> render(:error, message: "Failed to generate tokens")
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Invalid email or password")
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> render(:error, message: "Email and password are required")
  end

  @doc """
  Refreshes access token using refresh token from cookie.

  ## Response
    - 200: Returns new tokens
    - 401: Invalid or expired refresh token
  """
  def refresh(conn, _params) do
    case get_refresh_token_from_cookie(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> render(:error, message: "Refresh token not found")

      refresh_token ->
        case Accounts.refresh_tokens(refresh_token) do
          {:ok, new_access_token, new_refresh_token} ->
            conn
            |> put_http_cookie("access_token", new_access_token, max_age: 3600)
            |> put_http_cookie("refresh_token", new_refresh_token, max_age: 2_592_000)
            |> put_status(:ok)
            |> render(:refresh, access_token: new_access_token, refresh_token: new_refresh_token)

          {:error, _reason} ->
            conn
            |> delete_http_cookie("access_token")
            |> delete_http_cookie("refresh_token")
            |> put_status(:unauthorized)
            |> render(:error, message: "Invalid or expired refresh token")
        end
    end
  end

  @doc """
  Logs out the user by revoking all tokens and clearing cookies.

  ## Response
    - 200: Successfully logged out
  """
  def logout(conn, _params) do
    current_user = conn.assigns[:current_user]

    if current_user do
      Accounts.revoke_all_user_tokens(current_user)
    end

    conn
    |> delete_http_cookie("access_token")
    |> delete_http_cookie("refresh_token")
    |> put_status(:ok)
    |> render(:logout)
  end

  # Private functions

  defp put_http_cookie(conn, key, value, opts) do
    put_resp_cookie(
      conn,
      key,
      value,
      [
        http_only: true,
        secure: conn.scheme == :https,
        same_site: "Lax"
      ] ++ opts
    )
  end

  defp delete_http_cookie(conn, key) do
    delete_resp_cookie(conn, key)
  end

  defp get_refresh_token_from_cookie(conn) do
    conn.req_cookies["refresh_token"]
  end
end
