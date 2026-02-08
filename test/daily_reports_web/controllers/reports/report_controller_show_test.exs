defmodule DailyReportsWeb.Reports.ReportControllerShowTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})
    non_member = user_fixture(%{role: "Collaborator"})

    project = project_fixture()

    # Create a member for collaborator in project
    member_collaborator =
      member_fixture(%{project: project, user: collaborator, role: "Backend Developer"})

    # Create report for the project
    report =
      report_fixture(%{
        project: project,
        member: member_collaborator,
        title: "Test Report",
        summary: "Test Summary",
        report_date: "2026-02-08"
      })

    {:ok, master_token, _} = DailyReports.Accounts.generate_tokens(master)
    {:ok, manager_token, _} = DailyReports.Accounts.generate_tokens(manager)
    {:ok, collaborator_token, _} = DailyReports.Accounts.generate_tokens(collaborator)
    {:ok, non_member_token, _} = DailyReports.Accounts.generate_tokens(non_member)

    authenticated_conn_master =
      conn
      |> put_req_cookie("access_token", master_token)

    authenticated_conn_manager =
      conn
      |> put_req_cookie("access_token", manager_token)

    authenticated_conn_collaborator =
      conn
      |> put_req_cookie("access_token", collaborator_token)

    authenticated_conn_non_member =
      conn
      |> put_req_cookie("access_token", non_member_token)

    {:ok,
     conn: conn,
     master: master,
     manager: manager,
     collaborator: collaborator,
     non_member: non_member,
     project: project,
     report: report,
     authenticated_conn_master: authenticated_conn_master,
     authenticated_conn_manager: authenticated_conn_manager,
     authenticated_conn_collaborator: authenticated_conn_collaborator,
     authenticated_conn_non_member: authenticated_conn_non_member}
  end

  describe "show report" do
    test "Master can view any report", %{
      authenticated_conn_master: conn,
      report: report
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == report.id
      assert response["data"]["title"] == "Test Report"
      assert response["data"]["summary"] == "Test Summary"
      assert response["data"]["report_date"] == "2026-02-08"
    end

    test "Manager can view any report", %{
      authenticated_conn_manager: conn,
      report: report
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == report.id
      assert response["data"]["title"] == "Test Report"
    end

    test "Collaborator member can view reports from their project", %{
      authenticated_conn_collaborator: conn,
      report: report
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["id"] == report.id
      assert response["data"]["title"] == "Test Report"
    end

    test "returns 403 when non-member Collaborator tries to view report", %{
      authenticated_conn_non_member: conn,
      report: report
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project to view this report"
    end

    test "returns 401 when not authenticated", %{conn: conn, report: report} do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      assert json_response(conn, 401)
    end

    test "returns 404 when report does not exist", %{authenticated_conn_master: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/reports/#{non_existent_id}")

      assert json_response(conn, 404)["errors"]["detail"] =~ "Report not found"
    end

    test "returns 404 when non-member tries to access non-existent report", %{
      authenticated_conn_non_member: conn
    } do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/reports/#{non_existent_id}")

      assert json_response(conn, 404)["errors"]["detail"] =~ "Report not found"
    end

    test "includes preloaded project data", %{
      authenticated_conn_master: conn,
      report: report,
      project: project
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["project"]["id"] == project.id
      assert response["data"]["project"]["name"] == project.name
    end

    test "includes preloaded created_by data", %{
      authenticated_conn_master: conn,
      report: report
    } do
      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["created_by"]["id"] != nil
      assert response["data"]["created_by"]["role"] != nil
      assert response["data"]["created_by"]["user"]["name"] != nil
    end

    test "returns full report with all optional fields", %{
      authenticated_conn_master: conn,
      project: project
    } do
      member = member_fixture(%{project: project, user: user_fixture()})

      report =
        report_fixture(%{
          project: project,
          member: member,
          title: "Full Report",
          summary: "Full Summary",
          achievements: "Completed feature X",
          impediments: "Blocked by API issue",
          next_steps: "Deploy to production"
        })

      conn = get(conn, ~p"/api/reports/#{report.id}")

      response = json_response(conn, 200)
      assert response["data"]["title"] == "Full Report"
      assert response["data"]["summary"] == "Full Summary"
      assert response["data"]["achievements"] == "Completed feature X"
      assert response["data"]["impediments"] == "Blocked by API issue"
      assert response["data"]["next_steps"] == "Deploy to production"
    end

    test "Collaborator cannot view report from different project", %{
      collaborator: collaborator
    } do
      # Create another project with a report
      other_project = project_fixture(%{name: "Other Project", identifier: "OP-2026-02"})
      other_member = member_fixture(%{project: other_project, user: user_fixture()})

      other_report =
        report_fixture(%{
          project: other_project,
          member: other_member,
          title: "Other Project Report"
        })

      {:ok, token, _} = DailyReports.Accounts.generate_tokens(collaborator)

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> get(~p"/api/reports/#{other_report.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project"
    end
  end
end
