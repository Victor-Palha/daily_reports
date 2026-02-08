defmodule DailyReportsWeb.Reports.ReportController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.{Reports, Projects}
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Reports"])

  plug :authorize_create when action in [:create]
  plug :authorize_index when action in [:index]
  plug :authorize_show when action in [:show]

  defp authorize_create(conn, _opts) do
    current_user = conn.assigns.current_user
    project_id = conn.params["project_id"]

    # Allow Master and Manager to create reports for any project
    # Or allow if user is a member of the project
    cond do
      current_user.role in ["Master", "Manager"] ->
        conn

      is_binary(project_id) ->
        # Check if user has a member record for this project
        case Projects.get_member_by_project_and_user(project_id, current_user.id) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> json(%{errors: %{detail: "You must be a member of the project to create reports"}})
            |> halt()

          member ->
            # Store member_id for later use in create action
            assign(conn, :member_id, member.id)
        end

      true ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{detail: "project_id is required"}})
        |> halt()
    end
  end

  defp authorize_index(conn, _opts) do
    current_user = conn.assigns.current_user
    project_id = conn.params["project_id"]

    # Allow Master and Manager to view any project's reports
    # Or allow if user is a member of the project
    cond do
      current_user.role in ["Master", "Manager"] ->
        conn

      is_binary(project_id) ->
        case Projects.get_member_by_project_and_user(project_id, current_user.id) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> json(%{errors: %{detail: "You must be a member of the project to view reports"}})
            |> halt()

          _member ->
            conn
        end

      true ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{detail: "project_id is required"}})
        |> halt()
    end
  end

  defp authorize_show(conn, _opts) do
    current_user = conn.assigns.current_user
    report_id = conn.params["id"]

    # Allow Master and Manager to view any report
    # Or allow if user is a member of the report's project
    if current_user.role in ["Master", "Manager"] do
      conn
    else
      case Reports.get_report(report_id) do
        nil ->
          conn
          |> put_status(:not_found)
          |> json(%{errors: %{detail: "Report not found"}})
          |> halt()

        report ->
          report = Reports.preload_report(report)

          case Projects.get_member_by_project_and_user(report.project_id, current_user.id) do
            nil ->
              conn
              |> put_status(:forbidden)
              |> json(%{
                errors: %{detail: "You must be a member of the project to view this report"}
              })
              |> halt()

            _member ->
              assign(conn, :report, report)
          end
      end
    end
  end

  operation(:create,
    summary: "Create Report",
    description:
      "Creates a report for a project. Requires Master/Manager role or being a member of the project. The report_date defaults to today if not provided.",
    request_body: {
      "Report attributes",
      "application/json",
      Schemas.CreateReportRequest,
      required: true
    },
    responses: [
      created: {"Success", "application/json", Schemas.ReportResponse},
      bad_request: {"Invalid parameters", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse},
      unprocessable_entity: {
        "Validation errors",
        "application/json",
        Schemas.ValidationErrorResponse
      }
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Creates a new report for a project.

  Only Master/Manager users or members of the project can create reports.

  ## Parameters
    - project_id: Project ID (required)
    - created_by_id: Member ID (required, automatically set for Collaborators)
    - title: Report title (required)
    - summary: Report summary (required)
    - report_date: Report date (optional, defaults to today)
    - achievements: Achievements description (optional)
    - impediments: Impediments description (optional)
    - next_steps: Next steps description (optional)

  ## Response
    - 201: Returns created report data
    - 400: Invalid parameters or validation errors
    - 401: User not authenticated
    - 403: Insufficient permissions
    - 422: Validation errors
  """
  def create(conn, params) do
    # For Collaborators, use the member_id from authorization
    # For Master/Manager, they must provide created_by_id
    params =
      if conn.assigns[:member_id] do
        Map.put(params, "created_by_id", conn.assigns.member_id)
      else
        params
      end

    case Reports.create_report(params) do
      {:ok, report} ->
        conn
        |> put_status(:created)
        |> render(:show, report: report)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: DailyReportsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{detail: message}})
    end
  end

  operation(:index,
    summary: "List Reports",
    description:
      "Lists all reports from a project with filtering and pagination. Requires Master/Manager role or being a member of the project.",
    parameters: [
      project_id: [
        in: :query,
        type: :string,
        description: "Project ID (required)",
        required: true
      ],
      start_date: [
        in: :query,
        type: :string,
        description: "Filter reports from this date onwards (YYYY-MM-DD)",
        required: false
      ],
      end_date: [
        in: :query,
        type: :string,
        description: "Filter reports up to this date (YYYY-MM-DD)",
        required: false
      ],
      page: [
        in: :query,
        type: :integer,
        description: "Page number (default: 1)",
        required: false
      ],
      page_size: [
        in: :query,
        type: :integer,
        description: "Number of items per page (default: 20, max: 100)",
        required: false
      ]
    ],
    responses: [
      ok: {"Success", "application/json", Schemas.ReportsList},
      bad_request: {"Missing required parameters", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Lists all reports from a project with filtering and pagination.

  Only Master/Manager users or members of the project can view the reports.

  ## Query Parameters
    - project_id: Project ID (required)
    - start_date: Filter reports from this date onwards (optional, YYYY-MM-DD)
    - end_date: Filter reports up to this date (optional, YYYY-MM-DD)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Response
    - 200: Returns paginated report data with metadata
    - 400: Missing required project_id parameter
    - 401: User not authenticated
    - 403: Insufficient permissions
  """
  def index(conn, params) do
    if Map.has_key?(params, "project_id") do
      result = Reports.list_reports(params)

      conn
      |> put_status(:ok)
      |> render(:index, result)
    else
      conn
      |> put_status(:bad_request)
      |> json(%{errors: %{detail: "project_id parameter is required"}})
    end
  end

  operation(:show,
    summary: "Get Report",
    description:
      "Gets a single report by ID. Requires Master/Manager role or being a member of the report's project.",
    parameters: [
      id: [
        in: :path,
        type: :string,
        description: "Report ID",
        required: true
      ]
    ],
    responses: [
      ok: {"Success", "application/json", Schemas.ReportResponse},
      not_found: {"Report not found", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Gets a single report by ID.

  Only Master/Manager users or members of the report's project can view the report.

  ## Parameters
    - id: Report ID (required)

  ## Response
    - 200: Returns report data with preloaded associations
    - 401: User not authenticated
    - 403: Insufficient permissions
    - 404: Report not found
  """
  def show(conn, %{"id" => id}) do
    # For Master/Manager, we need to fetch and preload the report
    # For Collaborators, the report is already assigned in authorize_show
    report =
      if conn.assigns[:report] do
        conn.assigns.report
      else
        Reports.get_report(id)
      end

    case report do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Report not found"}})

      report ->
        report = Reports.preload_report(report)

        conn
        |> put_status(:ok)
        |> render(:show, report: report)
    end
  end
end
