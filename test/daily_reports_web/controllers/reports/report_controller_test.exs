defmodule DailyReportsWeb.Reports.ReportControllerTest do
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

    # Create a member for master (so they can be used as created_by_id)
    member_master = member_fixture(%{project: project, user: master, role: "Tech Lead"})

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
     member_collaborator: member_collaborator,
     member_master: member_master,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator}
  end

  describe "create report" do
    test "creates report as Master with full data", %{
      authenticated_conn_master: conn,
      project: project,
      member_master: member
    } do
      report_params = %{
        project_id: project.id,
        created_by_id: member.id,
        title: "Sprint Planning Report",
        summary: "Completed sprint planning for Q1",
        report_date: "2026-02-08",
        achievements: "Defined all user stories",
        impediments: "Need more team members",
        next_steps: "Start development next week"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["title"] == "Sprint Planning Report"
      assert data["summary"] == "Completed sprint planning for Q1"
      assert data["report_date"] == "2026-02-08"
      assert data["achievements"] == "Defined all user stories"
      assert data["impediments"] == "Need more team members"
      assert data["next_steps"] == "Start development next week"
      assert data["project_id"] == project.id
      assert data["created_by_id"] == member.id
      assert data["project"]["name"] == project.name
      assert data["created_by"]["user"]["name"] == member.user.name
    end

    test "creates report as Manager", %{
      authenticated_conn_manager: conn,
      project: project,
      member_master: member
    } do
      report_params = %{
        project_id: project.id,
        created_by_id: member.id,
        title: "Status Update",
        summary: "Weekly status update"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["title"] == "Status Update"
      assert data["summary"] == "Weekly status update"
    end

    test "creates report as project member (Collaborator)", %{
      authenticated_conn_collaborator: conn,
      project: project,
      member_collaborator: member
    } do
      # Collaborator doesn't need to provide created_by_id
      report_params = %{
        project_id: project.id,
        title: "Daily Progress",
        summary: "Implemented authentication"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["title"] == "Daily Progress"
      assert data["created_by_id"] == member.id
    end

    test "report_date defaults to today when not provided", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      report_params = %{
        project_id: project.id,
        title: "Today's Report",
        summary: "Work summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["report_date"] == to_string(Date.utc_today())
    end

    test "returns 403 when non-member Collaborator tries to create report", %{
      project: project
    } do
      non_member = user_fixture(%{role: "Collaborator"})
      {:ok, token, _} = DailyReports.Accounts.generate_tokens(non_member)

      report_params = %{
        project_id: project.id,
        title: "Unauthorized Report",
        summary: "Should not be created"
      }

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> post(~p"/api/reports", report_params)

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project to create reports"
    end

    test "returns 401 when not authenticated", %{conn: conn, project: project} do
      report_params = %{
        project_id: project.id,
        title: "Report",
        summary: "Summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert json_response(conn, 401)
    end

    test "returns 422 when title is missing", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      report_params = %{
        project_id: project.id,
        summary: "Summary without title"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors["title"] == ["can't be blank"]
    end

    test "returns 422 when summary is missing", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      report_params = %{
        project_id: project.id,
        title: "Title without summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"errors" => errors} = json_response(conn, 422)
      assert errors["summary"] == ["can't be blank"]
    end

    test "returns 400 when project_id is missing", %{
      authenticated_conn_collaborator: conn
    } do
      report_params = %{
        title: "Report",
        summary: "Summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert json_response(conn, 400)["errors"]["detail"] =~ "project_id is required"
    end

    test "returns 400 when project does not exist", %{
      authenticated_conn_master: conn,
      member_master: member
    } do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      report_params = %{
        project_id: non_existent_id,
        created_by_id: member.id,
        title: "Report",
        summary: "Summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert json_response(conn, 400)["errors"]["detail"] =~ "Project not found"
    end

    test "returns 400 when member does not exist", %{
      authenticated_conn_master: conn,
      project: project
    } do
      non_existent_id = "00000000-0000-0000-0000-000000000000"

      report_params = %{
        project_id: project.id,
        created_by_id: non_existent_id,
        title: "Report",
        summary: "Summary"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert json_response(conn, 400)["errors"]["detail"] =~ "Member not found"
    end

    test "allows optional fields to be nil", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      report_params = %{
        project_id: project.id,
        title: "Minimal Report",
        summary: "Just the basics"
      }

      conn = post(conn, ~p"/api/reports", report_params)

      assert %{"data" => data} = json_response(conn, 201)
      assert data["achievements"] == nil
      assert data["impediments"] == nil
      assert data["next_steps"] == nil
    end
  end
end
