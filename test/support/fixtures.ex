defmodule DailyReports.Fixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the schemas.
  """

  alias DailyReports.Repo
  alias DailyReports.Accounts.User
  alias DailyReports.Projects.{Project, Member}
  alias DailyReports.Reports.Report

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer([:positive])}@example.com"

  @doc """
  Generate a unique project identifier.
  """
  def unique_project_identifier do
    year = Date.utc_today().year
    id = System.unique_integer([:positive])
    "PRJ-#{year}-#{id}"
  end

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "Test User",
        email: unique_user_email(),
        password: "Password123!",
        role: "Collaborator",
        is_active: true
      })
      |> then(&User.registration_changeset(%User{}, &1))
      |> Repo.insert()

    user
  end

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        identifier: unique_project_identifier(),
        name: "Test Project",
        description: "A test project description",
        is_active: true
      })
      |> then(&Project.changeset(%Project{}, &1))
      |> Repo.insert()

    project
  end

  @doc """
  Generate a member.
  """
  def member_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user) || user_fixture()
    project = Map.get(attrs, :project) || project_fixture()

    {:ok, member} =
      attrs
      |> Enum.into(%{
        role: "Backend Developer"
      })
      |> Map.delete(:user)
      |> Map.delete(:project)
      |> then(&Member.changeset(%Member{}, &1))
      |> Ecto.Changeset.put_assoc(:user, user)
      |> Ecto.Changeset.put_assoc(:project, project)
      |> Repo.insert()

    member
  end

  @doc """
  Generate a report.
  """
  def report_fixture(attrs \\ %{}) do
    project = Map.get(attrs, :project) || project_fixture()
    member = Map.get(attrs, :member) || member_fixture(%{project: project})

    {:ok, report} =
      attrs
      |> Enum.into(%{
        title: "Daily Report",
        report_date: Date.utc_today(),
        summary: "Summary of the day",
        achievements: "Completed tasks A and B",
        impediments: "Waiting for API documentation",
        next_steps: "Continue with task C"
      })
      |> Map.delete(:project)
      |> Map.delete(:member)
      |> then(&Report.changeset(%Report{}, &1))
      |> Ecto.Changeset.put_assoc(:project, project)
      |> Ecto.Changeset.put_assoc(:created_by, member)
      |> Repo.insert()

    report
  end
end
