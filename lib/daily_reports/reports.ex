defmodule DailyReports.Reports do
  @moduledoc """
  The Reports context.
  """

  import Ecto.Query, warn: false
  alias DailyReports.Repo

  alias DailyReports.Reports.Report
  alias DailyReports.Projects

  @doc """
  Creates a report.

  ## Examples

      iex> create_report(%{field: value})
      {:ok, %Report{}}

      iex> create_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report(attrs \\ %{}) do
    # Validate that project exists
    with {:ok, _project} <- validate_project(attrs),
         {:ok, _member} <- validate_member(attrs) do
      %Report{}
      |> Report.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, report} -> {:ok, preload_report(report)}
        error -> error
      end
    end
  end

  @doc """
  Gets a single report.

  Returns nil if the Report does not exist.
  """
  def get_report(id), do: Repo.get(Report, id)

  @doc """
  Preloads associations for a report.
  """
  def preload_report(report) do
    Repo.preload(report, [:project, created_by: :user])
  end

  # Private functions

  defp validate_project(%{"project_id" => project_id}) when is_binary(project_id) do
    case Projects.get_project(project_id) do
      nil -> {:error, "Project not found"}
      project -> {:ok, project}
    end
  end

  defp validate_project(_attrs), do: {:error, "project_id is required"}

  defp validate_member(%{"created_by_id" => member_id}) when is_binary(member_id) do
    case Projects.get_member(member_id) do
      nil -> {:error, "Member not found"}
      member -> {:ok, member}
    end
  end

  defp validate_member(_attrs), do: {:error, "created_by_id is required"}
end
