defmodule DailyReportsWeb.Plugs.AuthorizeUserTest do
  use DailyReportsWeb.ConnCase, async: true

  alias DailyReportsWeb.Plugs.AuthorizeUser
  alias DailyReports.Fixtures

  describe "init/1" do
    test "raises error when roles option is missing" do
      assert_raise ArgumentError, "AuthorizeUser plug requires :roles option", fn ->
        AuthorizeUser.init([])
      end
    end

    test "raises error when roles option is empty" do
      assert_raise ArgumentError, "AuthorizeUser plug requires :roles option", fn ->
        AuthorizeUser.init(roles: [])
      end
    end

    test "accepts valid roles option" do
      assert %{roles: ["Master", "Manager"]} = AuthorizeUser.init(roles: ["Master", "Manager"])
    end
  end

  describe "call/2" do
    test "allows user with matching role" do
      user = Fixtures.user_fixture(%{role: "Master"})
      opts = AuthorizeUser.init(roles: ["Master", "Manager"])

      conn =
        build_conn()
        |> assign(:current_user, user)
        |> AuthorizeUser.call(opts)

      refute conn.halted
    end

    test "allows user with one of multiple allowed roles" do
      user = Fixtures.user_fixture(%{role: "Manager"})
      opts = AuthorizeUser.init(roles: ["Master", "Manager"])

      conn =
        build_conn()
        |> assign(:current_user, user)
        |> AuthorizeUser.call(opts)

      refute conn.halted
    end

    test "rejects user without matching role" do
      user = Fixtures.user_fixture(%{role: "Collaborator"})
      opts = AuthorizeUser.init(roles: ["Master", "Manager"])

      conn =
        build_conn()
        |> assign(:current_user, user)
        |> AuthorizeUser.call(opts)

      assert conn.halted
      assert conn.status == 403
      assert %{"errors" => %{"detail" => "Insufficient permissions"}} = json_response(conn, 403)
    end

    test "rejects request without current_user assign" do
      opts = AuthorizeUser.init(roles: ["Master", "Manager"])

      conn =
        build_conn()
        |> AuthorizeUser.call(opts)

      assert conn.halted
      assert conn.status == 401
      assert %{"errors" => %{"detail" => "Authentication required"}} = json_response(conn, 401)
    end

    test "works with single role" do
      user = Fixtures.user_fixture(%{role: "Master"})
      opts = AuthorizeUser.init(roles: ["Master"])

      conn =
        build_conn()
        |> assign(:current_user, user)
        |> AuthorizeUser.call(opts)

      refute conn.halted
    end

    test "rejects non-matching single role" do
      user = Fixtures.user_fixture(%{role: "Manager"})
      opts = AuthorizeUser.init(roles: ["Master"])

      conn =
        build_conn()
        |> assign(:current_user, user)
        |> AuthorizeUser.call(opts)

      assert conn.halted
      assert conn.status == 403
    end
  end
end
