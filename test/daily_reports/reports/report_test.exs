defmodule DailyReports.Reports.ReportTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Reports.Report
  alias DailyReports.Fixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          title: "Daily Report",
          summary: "Summary of the report",
          project_id: project.id,
          created_by_id: member.id,
          report_date: Date.utc_today()
        })

      assert changeset.valid?
    end

    test "invalid changeset without title" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          summary: "Summary",
          project_id: project.id,
          created_by_id: member.id,
          report_date: Date.utc_today()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "invalid changeset without summary" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          title: "Daily Report",
          project_id: project.id,
          created_by_id: member.id
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).summary
    end

    test "sets default report_date to today when not provided" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          title: "Daily Report",
          summary: "Summary",
          project_id: project.id,
          created_by_id: member.id
        })

      assert changeset.valid?
      assert get_change(changeset, :report_date) == Date.utc_today()
    end

    test "valid changeset with all optional fields" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          title: "Weekly Report",
          summary: "Week summary",
          project_id: project.id,
          created_by_id: member.id,
          report_date: Date.utc_today(),
          achievements: "Completed features X, Y, Z",
          impediments: "Blocked by API issues",
          next_steps: "Continue with feature A"
        })

      assert changeset.valid?
    end

    test "accepts past dates" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})
      past_date = Date.add(Date.utc_today(), -7)

      changeset =
        Report.changeset(%Report{}, %{
          title: "Past Report",
          summary: "Past summary",
          project_id: project.id,
          created_by_id: member.id,
          report_date: past_date
        })

      assert changeset.valid?
      assert get_change(changeset, :report_date) == past_date
    end
  end

  describe "inserting reports" do
    test "successfully creates a report with valid attributes" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      attrs = %{
        title: "Sprint Report",
        report_date: Date.utc_today(),
        summary: "Sprint completed successfully",
        achievements: "All tasks done",
        impediments: "None",
        next_steps: "Plan next sprint",
        project_id: project.id,
        created_by_id: member.id
      }

      changeset = Report.changeset(%Report{}, attrs)

      assert {:ok, report} = Repo.insert(changeset)

      assert report.title == attrs.title
      assert report.summary == attrs.summary
      assert report.achievements == attrs.achievements
      assert report.impediments == attrs.impediments
      assert report.next_steps == attrs.next_steps
      assert report.project_id == project.id
      assert report.created_by_id == member.id
    end

    test "successfully creates a report with only required fields" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      changeset =
        Report.changeset(%Report{}, %{
          title: "Minimal Report",
          summary: "Minimal summary",
          project_id: project.id,
          created_by_id: member.id,
          report_date: Date.utc_today()
        })

      assert {:ok, report} = Repo.insert(changeset)

      assert report.title == "Minimal Report"
      assert report.report_date == Date.utc_today()
      assert report.summary == "Minimal summary"
      assert is_nil(report.achievements)
    end

    test "allows reports from different members" do
      project = Fixtures.project_fixture()
      member1 = Fixtures.member_fixture(%{project: project})
      member2 = Fixtures.member_fixture(%{project: project})

      Fixtures.report_fixture(%{
        project: project,
        member: member1,
        title: "Member 1 Report"
      })

      changeset =
        Report.changeset(%Report{}, %{
          title: "Member 2 Report",
          summary: "Member 2 summary",
          project_id: project.id,
          created_by_id: member2.id,
          report_date: Date.utc_today()
        })

      assert {:ok, report} = Repo.insert(changeset)
      assert report.created_by_id == member2.id
    end
  end
end
