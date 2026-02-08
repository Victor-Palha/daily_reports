defmodule DailyReportsWeb.Reports.ReportControllerIndexTest do
  use DailyReportsWeb.ConnCase

  import DailyReports.Fixtures

  setup %{conn: conn} do
    master = user_fixture(%{role: "Master"})
    manager = user_fixture(%{role: "Manager"})
    collaborator = user_fixture(%{role: "Collaborator"})

    project = project_fixture()
    other_project = project_fixture(%{name: "Other Project", identifier: "OP-2026-01"})

    # Create a member for collaborator in project
    member_collaborator =
      member_fixture(%{project: project, user: collaborator, role: "Backend Developer"})

    # Create reports for the project with different dates
    _report1 =
      report_fixture(%{
        project: project,
        member: member_collaborator,
        title: "Report 1",
        report_date: "2026-02-01"
      })

    _report2 =
      report_fixture(%{
        project: project,
        member: member_collaborator,
        title: "Report 2",
        report_date: "2026-02-05"
      })

    _report3 =
      report_fixture(%{
        project: project,
        member: member_collaborator,
        title: "Report 3",
        report_date: "2026-02-08"
      })

    # Create report in other project
    other_member = member_fixture(%{project: other_project, user: user_fixture()})

    _other_report =
      report_fixture(%{
        project: other_project,
        member: other_member,
        title: "Other Project Report"
      })

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

  describe "list reports" do
    test "Master can list all reports from any project", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
      assert response["meta"]["total_count"] == 3
      assert response["meta"]["page"] == 1
    end

    test "Manager can list all reports from any project", %{
      authenticated_conn_manager: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end

    test "Collaborator member can list reports from their project", %{
      authenticated_conn_collaborator: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end

    test "returns 403 when non-member Collaborator tries to list reports", %{
      project: project
    } do
      non_member = user_fixture(%{role: "Collaborator"})
      {:ok, token, _} = DailyReports.Accounts.generate_tokens(non_member)

      conn =
        build_conn()
        |> put_req_cookie("access_token", token)
        |> get(~p"/api/reports?project_id=#{project.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project to view reports"
    end

    test "returns 401 when not authenticated", %{conn: conn, project: project} do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      assert json_response(conn, 401)
    end

    test "returns 400 when project_id is missing", %{authenticated_conn_master: conn} do
      conn = get(conn, ~p"/api/reports")

      assert json_response(conn, 400)["errors"]["detail"] =~ "project_id parameter is required"
    end

    test "filters by start_date", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}&start_date=2026-02-05")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      dates = Enum.map(response["data"], & &1["report_date"])
      assert "2026-02-05" in dates
      assert "2026-02-08" in dates
    end

    test "filters by end_date", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}&end_date=2026-02-05")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2

      dates = Enum.map(response["data"], & &1["report_date"])
      assert "2026-02-01" in dates
      assert "2026-02-05" in dates
    end

    test "filters by date range", %{authenticated_conn_master: conn, project: project} do
      conn =
        get(
          conn,
          ~p"/api/reports?project_id=#{project.id}&start_date=2026-02-02&end_date=2026-02-07"
        )

      response = json_response(conn, 200)
      assert length(response["data"]) == 1
      assert Enum.at(response["data"], 0)["report_date"] == "2026-02-05"
    end

    test "returns empty list for non-existent project", %{authenticated_conn_master: conn} do
      non_existent_id = "00000000-0000-0000-0000-000000000000"
      conn = get(conn, ~p"/api/reports?project_id=#{non_existent_id}")

      response = json_response(conn, 200)
      assert response["data"] == []
      assert response["meta"]["total_count"] == 0
    end

    test "supports pagination", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}&page=1&page_size=2")

      response = json_response(conn, 200)
      assert length(response["data"]) == 2
      assert response["meta"]["page_size"] == 2
      assert response["meta"]["total_pages"] == 2
    end

    test "enforces max page_size of 100", %{authenticated_conn_master: conn, project: project} do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}&page_size=200")

      response = json_response(conn, 200)
      assert response["meta"]["page_size"] == 100
    end

    test "includes preloaded project and created_by data", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      response = json_response(conn, 200)
      first_report = List.first(response["data"])

      assert first_report["project"]["id"] == project.id
      assert first_report["project"]["name"] != nil
      assert first_report["created_by"]["id"] != nil
      assert first_report["created_by"]["role"] != nil
      assert first_report["created_by"]["user"]["name"] != nil
    end

    test "reports are ordered by report_date desc", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}")

      response = json_response(conn, 200)
      dates = Enum.map(response["data"], & &1["report_date"])

      # Should be in descending order
      assert dates == ["2026-02-08", "2026-02-05", "2026-02-01"]
    end

    test "handles invalid date format gracefully", %{
      authenticated_conn_master: conn,
      project: project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{project.id}&start_date=invalid")

      # Should not crash, just ignore the invalid filter
      response = json_response(conn, 200)
      assert length(response["data"]) == 3
    end

    test "Collaborator cannot access other project reports", %{
      authenticated_conn_collaborator: conn,
      other_project: other_project
    } do
      conn = get(conn, ~p"/api/reports?project_id=#{other_project.id}")

      assert json_response(conn, 403)["errors"]["detail"] =~
               "You must be a member of the project"
    end
  end
end
