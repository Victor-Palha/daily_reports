defmodule DailyReportsWeb.Projects.ProjectControllerIndexTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})

    # Create some projects
    project1 = project_fixture(%{name: "Alpha Project", identifier: "AP-2026-01"})
    project2 = project_fixture(%{name: "Beta Project", identifier: "BP-2026-01"})
    project3 = project_fixture(%{name: "Gamma Project", identifier: "GP-2026-01"})

    # Make collaborator a member of only project1 and project2
    _member1 = member_fixture(%{project: project1, user: collaborator, role: "Backend Developer"})

    _member2 =
      member_fixture(%{project: project2, user: collaborator, role: "Frontend Developer"})

    # Create child project
    _child =
      project_fixture(%{name: "Child Project", identifier: "CP-2026-01", parent_id: project1.id})

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
     project1: project1,
     project2: project2,
     project3: project3,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "list projects" do
    test "Master sees all projects", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects")

      response = json_response(conn, 200)
      # 3 main projects + 1 child
      assert length(response["data"]) == 4
      assert response["meta"]["total_count"] == 4
      assert response["meta"]["page"] == 1
    end

    test "Manager sees all projects", %{authenticated_conn_manager: conn} do
      conn = get(conn, ~p"/api/projects")

      response = json_response(conn, 200)
      assert length(response["data"]) == 4
    end

    test "Collaborator sees only projects they are members of", %{
      authenticated_conn_collaborator: conn,
      project1: project1,
      project2: project2
    } do
      conn = get(conn, ~p"/api/projects")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      project_ids = Enum.map(response["data"], & &1["id"])
      assert project1.id in project_ids
      assert project2.id in project_ids
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/api/projects")

      assert json_response(conn, 401)
    end

    test "filters by name", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects?name=Alpha")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
      assert Enum.at(response["data"], 0)["name"] == "Alpha Project"
    end

    test "filters by name with partial match", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects?name=Project")

      response = json_response(conn, 200)
      # All projects contain "Project"
      assert length(response["data"]) == 4
    end

    test "filters by is_active", %{authenticated_conn_master: conn, project1: project1} do
      # Deactivate project1
      DailyReports.Repo.update!(Ecto.Changeset.change(project1, is_active: false))

      conn = get(conn, ~p"/api/projects?is_active=true")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3

      # Ensure deactivated project is not in results
      project_ids = Enum.map(response["data"], & &1["id"])
      refute project1.id in project_ids
    end

    test "filters by parent_id", %{authenticated_conn_master: conn, project1: project1} do
      conn = get(conn, ~p"/api/projects?parent_id=#{project1.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
      assert Enum.at(response["data"], 0)["name"] == "Child Project"
      assert Enum.at(response["data"], 0)["parent_id"] == project1.id
    end

    test "supports pagination", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects?page=1&page_size=2")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["page_size"] == 2
      assert response["meta"]["total_pages"] == 2
      assert response["meta"]["total_count"] == 4
    end

    test "enforces max page_size of 100", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects?page_size=200")

      response = json_response(conn, 200)
      assert response["meta"]["page_size"] == 100
    end

    test "combines multiple filters", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects?name=Project&is_active=true")

      response = json_response(conn, 200)
      assert response["meta"]["total_count"] >= 1

      # All results should be active and contain "Project"
      Enum.each(response["data"], fn project ->
        assert project["is_active"] == true
        assert String.contains?(project["name"], "Project")
      end)
    end

    test "returns empty list for Collaborator with no memberships" do
      non_member = user_fixture(%{role: "Collaborator"})
      {:ok, token, _} = DailyReports.Accounts.generate_tokens(non_member)

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> get(~p"/api/projects")

      response = json_response(conn, 200)
      assert response["data"] == []
      assert response["meta"]["total_count"] == 0
    end

    test "project data includes essential fields", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/projects")

      response = json_response(conn, 200)
      first_project = List.first(response["data"])

      assert first_project["id"] != nil
      assert first_project["identifier"] != nil
      assert first_project["name"] != nil
      assert first_project["is_active"] != nil
      assert first_project["created_at"] != nil
      assert first_project["updated_at"] != nil
    end

    test "Collaborator filter by name works on their projects", %{
      authenticated_conn_collaborator: conn
    } do
      conn = get(conn, ~p"/api/projects?name=Alpha")

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
      assert Enum.at(response["data"], 0)["name"] == "Alpha Project"
    end

    test "Collaborator filter returns empty for projects they're not member of", %{
      authenticated_conn_collaborator: conn
    } do
      conn = get(conn, ~p"/api/projects?name=Gamma")

      response = json_response(conn, 200)
      assert response["data"] == []
    end
  end
end
