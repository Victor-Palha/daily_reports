defmodule DailyReportsWeb.Projects.ProjectControllerTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  @create_attrs %{
    identifier: "VO-2026-01",
    name: "Test Project",
    description: "Test project description"
  }

  @invalid_attrs %{identifier: "invalid", name: nil}

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})

    {:ok, master_token, _} = DailyReports.Accounts.generate_tokens(master)
    {:ok, manager_token, _} = DailyReports.Accounts.generate_tokens(manager)
    {:ok, collaborator_token, _} = DailyReports.Accounts.generate_tokens(collaborator)

    authenticated_conn_master =
      conn
      |> put_req_cookie("access_token", master_token)

    authenticated_conn_manager =
      conn
      |> put_req_cookie("access_token", manager_token)

    authenticated_conn_collaborator =
      conn
      |> put_req_cookie("access_token", collaborator_token)

    {:ok,
     conn: conn,
     master: master,
     manager: manager,
     collaborator: collaborator,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "create project" do
    test "creates project when data is valid as Master", %{authenticated_conn_master: conn} do
      conn = post(conn, ~p"/api/projects", @create_attrs)

      assert %{"id" => _id} = json_response(conn, 201)["data"]

      assert %{"identifier" => "VO-2026-01", "name" => "Test Project"} =
               json_response(conn, 201)["data"]
    end

    test "creates project when data is valid as Manager", %{authenticated_conn_manager: conn} do
      conn = post(conn, ~p"/api/projects", @create_attrs)

      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end

    test "returns 403 when user is Collaborator", %{authenticated_conn_collaborator: conn} do
      conn = post(conn, ~p"/api/projects", @create_attrs)

      assert json_response(conn, 403)["errors"]["detail"] =~ "Insufficient permissions"
    end

    test "returns 401 when user is not authenticated", %{conn: conn} do
      conn = post(conn, ~p"/api/projects", @create_attrs)

      assert json_response(conn, 401)
    end

    test "returns errors when data is invalid", %{authenticated_conn_master: conn} do
      conn = post(conn, ~p"/api/projects", @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "creates child project when parent_id is valid", %{authenticated_conn_master: conn} do
      parent = project_fixture()

      child_attrs =
        @create_attrs
        |> Map.put(:identifier, "VO-2026-02")
        |> Map.put(:parent_id, parent.id)

      conn = post(conn, ~p"/api/projects", child_attrs)

      assert %{"id" => _id, "parent_id" => parent_id} = json_response(conn, 201)["data"]
      assert parent_id == parent.id
    end

    test "returns error when parent_id does not exist", %{authenticated_conn_master: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      attrs =
        @create_attrs
        |> Map.put(:parent_id, non_existent_id)

      conn = post(conn, ~p"/api/projects", attrs)

      assert json_response(conn, 400)["errors"]["parent_id"] =~ "does not exist"
    end

    test "returns error when parent project is not active", %{authenticated_conn_master: conn} do
      parent = project_fixture(%{is_active: false})

      child_attrs =
        @create_attrs
        |> Map.put(:identifier, "VO-2026-03")
        |> Map.put(:parent_id, parent.id)

      conn = post(conn, ~p"/api/projects", child_attrs)

      assert json_response(conn, 400)["errors"]["parent_id"] =~ "not active"
    end
  end
end
