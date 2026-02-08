defmodule DailyReportsWeb.Projects.MemberControllerTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  @invalid_attrs %{project_id: nil, user_id: nil, role: nil}

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})
    project = project_fixture()
    target_user = user_fixture()

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
     target_user: target_user,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "create member" do
    test "creates member when data is valid as Master", %{
      authenticated_conn_master: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert %{"id" => _id} = json_response(conn, 201)["data"]
      assert %{"role" => "Backend Developer"} = json_response(conn, 201)["data"]
      assert %{"project_id" => project_id} = json_response(conn, 201)["data"]
      assert project_id == project.id
    end

    test "creates member when data is valid as Manager", %{
      authenticated_conn_manager: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Frontend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end

    test "returns 403 when user is Collaborator", %{
      authenticated_conn_collaborator: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert json_response(conn, 403)["errors"]["detail"] =~ "Insufficient permissions"
    end

    test "returns 401 when user is not authenticated", %{
      conn: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert json_response(conn, 401)
    end

    test "returns errors when data is invalid", %{authenticated_conn_master: conn} do
      conn = post(conn, ~p"/api/members", @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns error when project does not exist", %{
      authenticated_conn_master: conn,
      target_user: user
    } do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      attrs = %{
        project_id: non_existent_id,
        user_id: user.id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert json_response(conn, 400)["errors"]["detail"] =~ "Project does not exist"
    end

    test "returns error when user does not exist", %{
      authenticated_conn_master: conn,
      project: project
    } do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      attrs = %{
        project_id: project.id,
        user_id: non_existent_id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert json_response(conn, 400)["errors"]["detail"] =~ "User does not exist"
    end

    test "returns error when user is already a member of the project", %{
      authenticated_conn_master: conn,
      project: project,
      target_user: user
    } do
      # Create the first member
      member_fixture(%{project: project, user: user, role: "Backend Developer"})

      # Try to add the same user again
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Frontend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      response = json_response(conn, 422)
      assert response["errors"] != %{}

      # The error could be a string or a list
      error = response["errors"]["project_id"]
      error_message = if is_list(error), do: Enum.join(error, " "), else: error
      assert error_message =~ "already a member"
    end

    test "returns error when role is invalid", %{
      authenticated_conn_master: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Invalid Role"
      }

      conn = post(conn, ~p"/api/members", attrs)

      assert json_response(conn, 422)["errors"]["role"] != nil
    end

    test "includes preloaded project and user data", %{
      authenticated_conn_master: conn,
      project: project,
      target_user: user
    } do
      attrs = %{
        project_id: project.id,
        user_id: user.id,
        role: "Backend Developer"
      }

      conn = post(conn, ~p"/api/members", attrs)

      response = json_response(conn, 201)["data"]

      assert response["project"]["id"] == project.id
      assert response["project"]["name"] == project.name
      assert response["user"]["id"] == user.id
      assert response["user"]["name"] == user.name
    end
  end
end
