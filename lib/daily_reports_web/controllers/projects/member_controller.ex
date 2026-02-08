defmodule DailyReportsWeb.Projects.MemberController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.Projects
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Members"])

  plug :authorize_create when action in [:create]
  plug :authorize_list when action in [:index]

  defp authorize_create(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
  end

  defp authorize_list(conn, _opts) do
    current_user = conn.assigns.current_user
    project_id = conn.params["project_id"]

    # Allow Master and Manager to view any project's members
    # Or allow if user is a member of the project
    if current_user.role in ["Master", "Manager"] or
         Projects.is_member?(project_id, current_user.id) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{errors: %{detail: "Insufficient permissions"}})
      |> halt()
    end
  end

  operation(:create,
    summary: "Create Member",
    description:
      "Adds a member to a project. Requires Master or Manager role. A user can only be a member of a project once.",
    request_body: {
      "Member attributes",
      "application/json",
      Schemas.CreateMemberRequest,
      required: true
    },
    responses: [
      created: {"Success", "application/json", Schemas.MemberResponse},
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
  Creates a new member for a project.

  Only Master and Manager role users can create members.
  Validates that both project and user exist before creating the member.
  A user can only be a member of a project once.

  ## Parameters
    - project_id: Project ID (required)
    - user_id: User ID (required)
    - role: Member role (required, must be one of the predefined roles)

  ## Response
    - 201: Returns created member data
    - 400: Invalid parameters or validation errors
    - 401: User not authenticated
    - 403: Insufficient permissions
    - 422: Validation errors (e.g., user already member of project)
  """
  def create(conn, params) do
    case Projects.create_member(params) do
      {:ok, member} ->
        member = Projects.preload_members(member)

        conn
        |> put_status(:created)
        |> render(:show, member: member)

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
    summary: "List Members",
    description:
      "Lists all members of a project with filtering and pagination. Requires Master/Manager role or being a member of the project.",
    parameters: [
      project_id: [
        in: :query,
        type: :string,
        description: "Project ID (required)",
        required: true
      ],
      role: [
        in: :query,
        type: :string,
        description: "Filter by member role (optional)",
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
      ok: {"Success", "application/json", Schemas.MembersList},
      bad_request: {"Missing required parameters", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Lists all members of a project with filtering and pagination.

  Only Master/Manager users or members of the project can view the member list.

  ## Query Parameters
    - project_id: Project ID (required)
    - role: Filter by member role (optional)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Response
    - 200: Returns paginated member data with metadata
    - 400: Missing required project_id parameter
    - 401: User not authenticated
    - 403: Insufficient permissions
  """
  def index(conn, params) do
    if Map.has_key?(params, "project_id") do
      result = Projects.list_members(params)

      conn
      |> put_status(:ok)
      |> render(:index, result)
    else
      conn
      |> put_status(:bad_request)
      |> json(%{errors: %{detail: "project_id parameter is required"}})
    end
  end
end
