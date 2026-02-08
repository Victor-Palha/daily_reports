defmodule DailyReportsWeb.Reports.ReportController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.{Reports, Projects}
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Reports"])

  plug :authorize_create when action in [:create]

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
end
