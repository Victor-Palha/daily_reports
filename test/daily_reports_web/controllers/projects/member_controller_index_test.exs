defmodule DailyReportsWeb.Projects.MemberControllerIndexTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})
    project = project_fixture()

    # Create some members for the project
    _member1 =
      member_fixture(%{project: project, user: user_fixture(), role: "Backend Developer"})

    _member2 =
      member_fixture(%{project: project, user: user_fixture(), role: "Frontend Developer"})

    _member3 =
      member_fixture(%{project: project, user: user_fixture(), role: "Backend Developer"})

    # Make collaborator a member of the project
    _member_collaborator =
      member_fixture(%{project: project, user: collaborator, role: "QA Engineer"})

    # Create another project with a member that should not show up
    other_project = project_fixture()

    _other_member =
      member_fixture(%{project: other_project, user: user_fixture(), role: "DevOps Engineer"})

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
     project: project,
     other_project: other_project,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "list members" do
    test "lists all members of a project as Master", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 4
      assert response["meta"]["total_count"] == 4
      assert response["meta"]["page"] == 1
    end

    test "lists all members of a project as Manager", %{
      authenticated_conn_manager: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 4
    end

    test "allows project member (Collaborator) to view members", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 4
    end

    test "returns 403 when non-member Collaborator tries to view members", %{
      project: project
    } do
      non_member_collab = user_fixture(%{role: "Collaborator"})
      {:ok, token, _} = DailyReports.Accounts.generate_tokens(non_member_collab)

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> get(~p"/api/members?project_id=#{project.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~ "Insufficient permissions"
    end

    test "returns 401 when not authenticated", %{conn: conn, project: project} do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}")

      assert json_response(conn, 401)
    end

    test "returns 400 when project_id is missing", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/members")

      assert json_response(conn, 400)["errors"]["detail"] =~ "project_id parameter is required"
    end

    test "filters by role", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}&role=Backend Developer")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert Enum.all?(response["data"], fn m -> m["role"] == "Backend Developer" end)
    end

    test "returns empty list for non-existent project", %{authenticated_conn_master: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/members?project_id=#{non_existent_id}")

      response = json_response(conn, 200)
      assert response["data"] == []
      assert response["meta"]["total_count"] == 0
    end

    test "supports pagination", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}&page=1&page_size=2")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["page_size"] == 2
      assert response["meta"]["total_pages"] == 2
    end

    test "includes preloaded project and user data", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}")

      response = json_response(conn, 200)
      first_member = List.first(response["data"])

      assert first_member["project"]["id"] == project.id
      assert first_member["project"]["name"] != nil
      assert first_member["user"]["id"] != nil
      assert first_member["user"]["name"] != nil
    end

    test "enforces max page_size of 100", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/members?project_id=#{project.id}&page_size=200")

      response = json_response(conn, 200)
      assert response["meta"]["page_size"] == 100
    end
  end
end
