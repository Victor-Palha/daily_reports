defmodule DailyReportsWeb.Projects.ProjectController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.Projects
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Projects"])

  plug :authorize_create when action in [:create]
  plug :authorize_show when action in [:show]

  defp authorize_create(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
  end

  defp authorize_show(conn, _opts) do
    current_user = conn.assigns.current_user
    project_id = conn.params["id"]

    # Allow Master and Manager to view any project
    # Or allow if user is a member of the project
    cond do
      current_user.role in ["Master", "Manager"] ->
        conn

      is_binary(project_id) ->
        case Projects.get_member_by_project_and_user(project_id, current_user.id) do
          nil ->
            conn
            |> put_status(:forbidden)
            |> json(%{errors: %{detail: "You must be a member of the project to view it"}})
            |> halt()

          _member ->
            conn
        end

      true ->
        conn
    end
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

  operation(:show,
    summary: "Get Project",
    description:
      "Retrieves a project with all its reports, members, and children. Requires Master/Manager role or being a member of the project.",
    parameters: [
      id: [
        in: :path,
        type: :string,
        description: "Project ID",
        required: true
      ]
    ],
    responses: [
      ok: {"Success", "application/json", Schemas.ProjectResponse},
      not_found: {"Project not found", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Gets a single project with all related data.

  Only Master/Manager users or members of the project can retrieve the project.
  Returns the project with all reports, members, and children ordered by created_at.

  ## Parameters
    - id: Project ID (required)

  ## Response
    - 200: Returns project data with reports, members, and children
    - 401: User not authenticated
    - 403: Insufficient permissions
    - 404: Project not found
  """
  def show(conn, %{"id" => id}) do
    case Projects.get_project_with_details(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Project not found"}})

      project ->
        conn
        |> put_status(:ok)
        |> render(:show, project: project)
    end
  end

  operation(:index,
    summary: "List Projects",
    description:
      "Lists all projects with filtering and pagination. Master/Manager users see all projects, Collaborators see only projects they are members of.",
    parameters: [
      name: [
        in: :query,
        type: :string,
        description: "Filter by project name (partial match)",
        required: false
      ],
      is_active: [
        in: :query,
        type: :string,
        description: "Filter by active status (true/false)",
        required: false
      ],
      parent_id: [
        in: :query,
        type: :string,
        description: "Filter by parent project ID",
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
      ok: {"Success", "application/json", Schemas.ProjectsList},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Lists all projects with filtering and pagination.

  Master/Manager users see all projects.
  Collaborator users see only projects they are members of.

  ## Query Parameters
    - name: Filter by project name (optional, partial match)
    - is_active: Filter by active status (optional, true/false)
    - parent_id: Filter by parent project ID (optional)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Response
    - 200: Returns paginated project data with metadata
    - 401: User not authenticated
  """
  def index(conn, params) do
    current_user = conn.assigns.current_user
    result = Projects.list_projects(current_user, params)

    conn
    |> put_status(:ok)
    |> render(:index, result)
  end
end
