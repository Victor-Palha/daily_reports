defmodule DailyReportsWeb.Accounts.AuthControllerTest do
  use DailyReportsWeb.ConnCase, async: true

  alias DailyReports.Fixtures
  alias DailyReports.Accounts

  describe "POST /api/auth/login" do
    test "authenticates user with valid credentials", %{conn: conn} do
      password = "Password123!"
      user = Fixtures.user_fixture(%{password: password})

      conn =
        post(conn, ~p"/api/auth/login", %{
          email: user.email,
          password: password
        })

      assert %{
               "data" => %{
                 "user" => user_data,
                 "access_token" => access_token,
                 "refresh_token" => refresh_token
               }
             } = json_response(conn, 200)

      assert user_data["id"] == user.id
      assert user_data["email"] == user.email
      assert is_binary(access_token)
      assert is_binary(refresh_token)

      # Verify cookies are set
      assert get_resp_cookie(conn, "access_token")
      assert get_resp_cookie(conn, "refresh_token")
    end

    test "returns error with invalid credentials", %{conn: conn} do
      user = Fixtures.user_fixture(%{password: "CorrectPassword123!"})

      conn =
        post(conn, ~p"/api/auth/login", %{
          email: user.email,
          password: "WrongPassword"
        })

      assert %{"errors" => %{"detail" => "Invalid email or password"}} = json_response(conn, 401)
    end

    test "returns error with non-existent email", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/login", %{
          email: "nonexistent@example.com",
          password: "password"
        })

      assert %{"errors" => %{"detail" => "Invalid email or password"}} = json_response(conn, 401)
    end

    test "returns error when email is missing", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/login", %{
          password: "password"
        })

      assert %{"errors" => %{"detail" => "Email and password are required"}} =
               json_response(conn, 400)
    end

    test "returns error when password is missing", %{conn: conn} do
      conn =
        post(conn, ~p"/api/auth/login", %{
          email: "user@example.com"
        })

      assert %{"errors" => %{"detail" => "Email and password are required"}} =
               json_response(conn, 400)
    end

    test "does not expose sensitive user information", %{conn: conn} do
      password = "Password123!"
      user = Fixtures.user_fixture(%{password: password})

      conn =
        post(conn, ~p"/api/auth/login", %{
          email: user.email,
          password: password
        })

      assert %{"data" => %{"user" => user_data}} = json_response(conn, 200)

      refute Map.has_key?(user_data, "password")
      refute Map.has_key?(user_data, "password_hash")
    end
  end

  describe "POST /api/auth/refresh" do
    test "refreshes tokens with valid refresh token", %{conn: conn} do
      user = Fixtures.user_fixture()
      {:ok, _access_token, refresh_token} = Accounts.generate_tokens(user)

      conn =
        conn
        |> put_req_cookie("refresh_token", refresh_token)
        |> post(~p"/api/auth/refresh")

      assert %{
               "data" => %{
                 "access_token" => new_access_token,
                 "refresh_token" => new_refresh_token
               }
             } = json_response(conn, 200)

      assert is_binary(new_access_token)
      assert is_binary(new_refresh_token)
      assert new_refresh_token != refresh_token

      # Verify cookies are updated
      assert get_resp_cookie(conn, "access_token")
      assert get_resp_cookie(conn, "refresh_token")
    end

    test "returns error when refresh token is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/refresh")

      assert %{"errors" => %{"detail" => "Refresh token not found"}} = json_response(conn, 401)
    end

    test "returns error with invalid refresh token", %{conn: conn} do
      conn =
        conn
        |> put_req_cookie("refresh_token", "invalid_token")
        |> post(~p"/api/auth/refresh")

      assert %{"errors" => %{"detail" => "Invalid or expired refresh token"}} =
               json_response(conn, 401)

      # Verify cookies are cleared
      conn = fetch_cookies(conn)
      assert %{max_age: 0} = conn.resp_cookies["access_token"]
      assert %{max_age: 0} = conn.resp_cookies["refresh_token"]
    end
  end

  describe "POST /api/auth/logout" do
    setup %{conn: conn} do
      user = Fixtures.user_fixture()
      {:ok, access_token, refresh_token} = Accounts.generate_tokens(user)

      conn =
        conn
        |> put_req_cookie("access_token", access_token)
        |> put_req_cookie("refresh_token", refresh_token)

      %{conn: conn, user: user, access_token: access_token, refresh_token: refresh_token}
    end

    test "logs out authenticated user and revokes tokens", %{
      conn: conn,
      user: _user,
      refresh_token: refresh_token
    } do
      # Authenticate the connection
      conn = fetch_cookies(conn)
      {:ok, authenticated_user, _claims} = Accounts.verify_token(conn.req_cookies["access_token"])

      conn =
        conn
        |> assign(:current_user, authenticated_user)
        |> post(~p"/api/auth/logout")

      assert %{"data" => %{"message" => "Successfully logged out"}} = json_response(conn, 200)

      # Verify cookies are cleared
      conn = fetch_cookies(conn)
      assert %{max_age: 0} = conn.resp_cookies["access_token"]
      assert %{max_age: 0} = conn.resp_cookies["refresh_token"]

      # Verify refresh token is revoked
      stored_token = Repo.get_by(DailyReports.Accounts.RefreshToken, token: refresh_token)
      assert stored_token.revoked_at != nil
    end

    test "logs out without authentication", %{conn: conn} do
      conn = post(conn, ~p"/api/auth/logout")

      assert %{"data" => %{"message" => "Successfully logged out"}} = json_response(conn, 200)
    end
  end
end
