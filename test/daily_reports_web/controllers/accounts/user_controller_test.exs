defmodule DailyReportsWeb.Accounts.UserControllerTest do
  use DailyReportsWeb.ConnCase, async: true

  alias DailyReports.Fixtures
  alias DailyReports.Accounts

  describe "GET /api/users/me" do
    setup %{conn: conn} do
      user = Fixtures.user_fixture()
      {:ok, access_token, _refresh_token} = Accounts.generate_tokens(user)

      conn =
        conn
        |> put_req_cookie("access_token", access_token)

      %{conn: conn, user: user}
    end

    test "returns current user profile when authenticated", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/me")

      assert %{"data" => user_data} = json_response(conn, 200)

      assert user_data["id"] == user.id
      assert user_data["email"] == user.email
      assert user_data["name"] == user.name
      assert user_data["role"] == user.role
      assert user_data["is_active"] == user.is_active
    end

    test "does not expose sensitive information", %{conn: conn} do
      conn = get(conn, ~p"/api/users/me")

      assert %{"data" => user_data} = json_response(conn, 200)

      refute Map.has_key?(user_data, "password")
      refute Map.has_key?(user_data, "password_hash")
    end

    test "returns 401 when not authenticated" do
      conn = build_conn() |> get(~p"/api/users/me")

      assert %{"errors" => %{"detail" => "Authentication required"}} = json_response(conn, 401)
    end

    test "returns 401 with invalid token", %{conn: conn_base} do
      conn =
        conn_base
        |> put_req_cookie("access_token", "invalid_token")
        |> get(~p"/api/users/me")

      assert %{"errors" => %{"detail" => "Invalid or expired token"}} = json_response(conn, 401)
    end
  end

  describe "PUT /api/users/me" do
    setup %{conn: conn} do
      user = Fixtures.user_fixture()
      {:ok, access_token, _refresh_token} = Accounts.generate_tokens(user)

      conn =
        conn
        |> put_req_cookie("access_token", access_token)

      %{conn: conn, user: user}
    end

    test "updates user profile with valid data", %{conn: conn, user: user} do
      new_name = "Updated Name"

      conn =
        put(conn, ~p"/api/users/me", %{
          name: new_name
        })

      assert %{"data" => user_data} = json_response(conn, 200)

      assert user_data["id"] == user.id
      assert user_data["name"] == new_name
      assert user_data["email"] == user.email
    end

    test "updates user email with valid data", %{conn: conn, user: user} do
      new_email = Fixtures.unique_user_email()

      conn =
        put(conn, ~p"/api/users/me", %{
          email: new_email
        })

      assert %{"data" => user_data} = json_response(conn, 200)

      assert user_data["id"] == user.id
      assert user_data["email"] == new_email
    end

    test "returns error with invalid email", %{conn: conn} do
      conn =
        put(conn, ~p"/api/users/me", %{
          email: "invalid-email"
        })

      assert %{"errors" => errors} = json_response(conn, 422)
      assert Map.has_key?(errors, "email")
    end

    test "returns error with duplicate email", %{conn: conn} do
      other_user = Fixtures.user_fixture()

      conn =
        put(conn, ~p"/api/users/me", %{
          email: other_user.email
        })

      assert %{"errors" => errors} = json_response(conn, 422)
      assert Map.has_key?(errors, "email")
    end

    test "ignores disallowed parameters", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/api/users/me", %{
          role: "Manager",
          is_active: false,
          password_hash: "hacked"
        })

      assert %{"data" => user_data} = json_response(conn, 200)

      # User data should remain unchanged for protected fields
      assert user_data["role"] == user.role
      assert user_data["is_active"] == user.is_active
    end

    test "returns 401 when not authenticated" do
      conn =
        build_conn()
        |> put(~p"/api/users/me", %{
          name: "New Name"
        })

      assert %{"errors" => %{"detail" => "Authentication required"}} = json_response(conn, 401)
    end
  end
end
