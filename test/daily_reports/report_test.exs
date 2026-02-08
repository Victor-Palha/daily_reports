defmodule DailyReports.ReportTest do
  use DailyReports.DataCase, async: true

  alias DailyReports.Report
  alias DailyReports.Fixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset =
        Report.changeset(%Report{}, %{
          title: "Daily Report",
          report_date: Date.utc_today()
        })

      assert changeset.valid?
    end

    test "invalid changeset without title" do
      changeset =
        Report.changeset(%Report{}, %{
          report_date: Date.utc_today()
        })

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).title
    end

    test "invalid changeset without report_date" do
      changeset = Report.changeset(%Report{}, %{title: "Daily Report"})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).report_date
    end

    test "sets default report_date to today when not provided" do
      changeset = Report.changeset(%Report{}, %{title: "Daily Report"})

      # Note: the changeset will have a report_date set, but it's still invalid
      # because the validation runs after the default is set
      assert get_change(changeset, :report_date) == Date.utc_today()
    end

    test "valid changeset with all optional fields" do
      changeset =
        Report.changeset(%Report{}, %{
          title: "Weekly Report",
          report_date: Date.utc_today(),
          summary: "Week summary",
          achievements: "Completed features X, Y, Z",
          impediments: "Blocked by API issues",
          next_steps: "Continue with feature A"
        })

      assert changeset.valid?
    end

    test "accepts past dates" do
      past_date = Date.add(Date.utc_today(), -7)

      changeset =
        Report.changeset(%Report{}, %{
          title: "Past Report",
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
        next_steps: "Plan next sprint"
      }

      changeset =
        Report.changeset(%Report{}, attrs)
        |> Ecto.Changeset.put_assoc(:project, project)
        |> Ecto.Changeset.put_assoc(:created_by, member)

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
          report_date: Date.utc_today()
        })
        |> Ecto.Changeset.put_assoc(:project, project)
        |> Ecto.Changeset.put_assoc(:created_by, member)

      assert {:ok, report} = Repo.insert(changeset)

      assert report.title == "Minimal Report"
      assert report.report_date == Date.utc_today()
      assert is_nil(report.summary)
      assert is_nil(report.achievements)
    end

    test "allows multiple reports for same project" do
      project = Fixtures.project_fixture()
      member = Fixtures.member_fixture(%{project: project})

      Fixtures.report_fixture(%{
        project: project,
        member: member,
        title: "Report 1"
      })

      changeset =
        Report.changeset(%Report{}, %{
          title: "Report 2",
          report_date: Date.utc_today()
        })
        |> Ecto.Changeset.put_assoc(:project, project)
        |> Ecto.Changeset.put_assoc(:created_by, member)

      assert {:ok, report} = Repo.insert(changeset)
      assert report.title == "Report 2"
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
          report_date: Date.utc_today()
        })
        |> Ecto.Changeset.put_assoc(:project, project)
        |> Ecto.Changeset.put_assoc(:created_by, member2)

      assert {:ok, report} = Repo.insert(changeset)
      assert report.created_by_id == member2.id
    end
  end
end
