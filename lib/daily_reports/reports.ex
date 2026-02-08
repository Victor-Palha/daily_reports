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
  Lists reports from a project with filtering and pagination.

  ## Parameters
    - project_id: Project ID (required)
    - start_date: Filter reports from this date onwards (optional)
    - end_date: Filter reports up to this date (optional)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Examples

      iex> list_reports(%{"project_id" => project_id})
      %{data: [%Report{}], meta: %{total_count: 5, page: 1, page_size: 20, total_pages: 1}}

  """
  def list_reports(params) do
    project_id = Map.get(params, "project_id")
    start_date = Map.get(params, "start_date")
    end_date = Map.get(params, "end_date")
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = min(Map.get(params, "page_size", "20") |> String.to_integer(), 100)

    query =
      Report
      |> where([r], r.project_id == ^project_id)
      |> order_by([r], desc: r.report_date, desc: r.inserted_at)

    # Apply date filters
    query =
      if start_date do
        case Date.from_iso8601(start_date) do
          {:ok, date} -> where(query, [r], r.report_date >= ^date)
          _ -> query
        end
      else
        query
      end

    query =
      if end_date do
        case Date.from_iso8601(end_date) do
          {:ok, date} -> where(query, [r], r.report_date <= ^date)
          _ -> query
        end
      else
        query
      end

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_count / page_size)

    reports =
      query
      |> limit(^page_size)
      |> offset(^((page - 1) * page_size))
      |> preload([:project, created_by: :user])
      |> Repo.all()

    %{
      data: reports,
      meta: %{
        total_count: total_count,
        page: page,
        page_size: page_size,
        total_pages: total_pages
      }
    }
  end

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
