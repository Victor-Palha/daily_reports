defmodule DailyReportsWeb.Projects.ProjectControllerShowTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})

    project = project_fixture()

    # Create a member for collaborator
    member_collaborator =
      member_fixture(%{project: project, user: collaborator, role: "Backend Developer"})

    # Create some reports for the project
    _report1 = report_fixture(%{project: project, member: member_collaborator, title: "Report 1"})
    _report2 = report_fixture(%{project: project, member: member_collaborator, title: "Report 2"})

    # Create another member
    another_user = user_fixture()
    _member2 = member_fixture(%{project: project, user: another_user, role: "Frontend Developer"})

    # Create child projects
    _child1 =
      project_fixture(%{name: "Child Project 1", parent_id: project.id, identifier: "CH-2026-01"})

    _child2 =
      project_fixture(%{name: "Child Project 2", parent_id: project.id, identifier: "CH-2026-02"})

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
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "show project" do
    test "retrieves project as Master with all data", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == project.id
      assert data["name"] == project.name
      assert data["identifier"] == project.identifier

      # Should have reports
      assert is_list(data["reports"])
      assert length(data["reports"]) == 2

      # Reports should have titles
      report_titles = Enum.map(data["reports"], & &1["title"])
      assert "Report 1" in report_titles
      assert "Report 2" in report_titles

      # Should have members
      assert is_list(data["members"])
      assert length(data["members"]) == 2

      # Members should have user data
      first_member = Enum.at(data["members"], 0)
      assert first_member["user"]["name"] != nil
      assert first_member["role"] != nil

      # Should have children
      assert is_list(data["children"])
      assert length(data["children"]) == 2

      # Children should have names
      children_names = Enum.map(data["children"], & &1["name"])
      assert "Child Project 1" in children_names
      assert "Child Project 2" in children_names
    end

    test "retrieves project as Manager", %{
      authenticated_conn_manager: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == project.id
      assert is_list(data["reports"])
      assert is_list(data["members"])
      assert is_list(data["children"])
    end

    test "allows project member (Collaborator) to view project", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["id"] == project.id
      assert data["name"] == project.name
    end

    test "returns 403 when non-member Collaborator tries to view project", %{
      project: project
    } do
      non_member = user_fixture(%{role: "Collaborator"})
      {:ok, token, _} = DailyReports.Accounts.generate_tokens(non_member)

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> get(~p"/api/projects/#{project.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project to view it"
    end

    test "returns 401 when not authenticated", %{conn: conn, project: project} do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert json_response(conn, 401)
    end

    test "returns 404 when project does not exist", %{authenticated_conn_master: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/projects/#{non_existent_id}")

      assert json_response(conn, 404)["errors"]["detail"] =~ "Project not found"
    end

    test "reports include created_by with user data", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      first_report = List.first(data["reports"])

      assert first_report["created_by"]["id"] != nil
      assert first_report["created_by"]["role"] != nil
      assert first_report["created_by"]["user"]["name"] != nil
      assert first_report["created_by"]["user"]["email"] != nil
    end

    test "children projects have basic info", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/projects/#{project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      first_child = List.first(data["children"])

      assert first_child["id"] != nil
      assert first_child["identifier"] != nil
      assert first_child["name"] != nil
      assert first_child["is_active"] != nil
      assert first_child["created_at"] != nil
    end

    test "project without reports, members, or children returns empty arrays", %{
      authenticated_conn_master: conn
    } do
      empty_project = project_fixture(%{name: "Empty Project", identifier: "EP-2026-01"})
      conn = get(conn, ~p"/api/projects/#{empty_project.id}")

      assert %{"data" => data} = json_response(conn, 200)
      assert data["reports"] == []
      assert data["members"] == []
      assert data["children"] == []
    end
  end
end
