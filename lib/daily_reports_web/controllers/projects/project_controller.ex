defmodule DailyReportsWeb.Projects.ProjectController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.Projects
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Projects"])

  plug :authorize_create when action in [:create]

  defp authorize_create(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
  end

  operation(:create,
    summary: "Create Project",
    description:
      "Creates a new project. Requires Master or Manager role. Can create child projects by providing parent_id.",
    request_body: {
      "Project attributes",
      "application/json",
      Schemas.CreateProjectRequest,
      required: true
    },
    responses: [
      created: {"Success", "application/json", Schemas.ProjectResponse},
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
  Creates a new project.

  Only Master and Manager role users can create projects.
  If parent_id is provided, validates that the parent project exists and is active.

  ## Parameters
    - identifier: Project identifier in format XX-YYYY-NN (required)
    - name: Project name (required)
    - description: Project description (optional)
    - parent_id: Parent project ID for creating child projects (optional)

  ## Response
    - 201: Returns created project data
    - 400: Invalid parameters or parent project validation error
    - 401: User not authenticated
    - 403: Insufficient permissions
    - 422: Validation errors
  """
  def create(conn, params) do
    case Projects.create_project(params) do
      {:ok, project} ->
        conn
        |> put_status(:created)
        |> render(:show, project: project)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: DailyReportsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)

      {:error, message} when is_binary(message) ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{parent_id: message}})
    end
  end
end
