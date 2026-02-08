defmodule DailyReportsWeb.Accounts.UserController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.Accounts
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Users"])

  plug :authorize_create when action in [:create]
  plug :authorize_list when action in [:index]

  defp authorize_create(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
  end

  defp authorize_list(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
  end

  operation(:index,
    summary: "List Users",
    description:
      "Lists all users with filtering and pagination. Requires Master or Manager role.",
    parameters: [
      name: [
        in: :query,
        type: :string,
        description: "Filter by name (case-insensitive partial match)",
        required: false
      ],
      role: [
        in: :query,
        type: :string,
        description: "Filter by role (Master, Manager, or Collaborator)",
        required: false
      ],
      is_active: [
        in: :query,
        type: :boolean,
        description: "Filter by active status",
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
      ok: {"Success", "application/json", Schemas.UsersList},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      forbidden: {"Insufficient permissions", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Lists all users with filtering and pagination.

  Only Master and Manager role users can list users.

  ## Query Parameters
    - name: Filter by name (case-insensitive partial match)
    - role: Filter by role ("Master", "Manager", or "Collaborator")
    - is_active: Filter by active status ("true" or "false")
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Response
    - 200: Returns paginated user data with metadata
    - 401: User not authenticated
    - 403: Insufficient permissions
  """
  def index(conn, params) do
    result = Accounts.list_users(params)

    conn
    |> put_status(:ok)
    |> render(:index, result)
  end

  operation(:me,
    summary: "Get Current User",
    description: "Returns the current authenticated user's profile",
    responses: [
      ok: {"Success", "application/json", Schemas.UserResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse}
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Returns the current authenticated user's profile.

  ## Response
    - 200: Returns user data
    - 401: User not authenticated
  """
  def me(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> put_status(:ok)
    |> render(:show, user: user)
  end

  operation(:update,
    summary: "Update Current User",
    description: "Updates the current authenticated user's profile",
    request_body: {
      "Update user attributes",
      "application/json",
      Schemas.UpdateUserRequest
    },
    responses: [
      ok: {"Success", "application/json", Schemas.UserResponse},
      bad_request: {"Invalid parameters", "application/json", Schemas.ErrorResponse},
      unauthorized: {"Not authenticated", "application/json", Schemas.ErrorResponse},
      unprocessable_entity: {
        "Validation errors",
        "application/json",
        Schemas.ValidationErrorResponse
      }
    ],
    security: [%{"cookieAuth" => []}]
  )

  @doc """
  Updates the current authenticated user's profile.

  ## Parameters
    - name: User's name (optional)
    - email: User's email (optional)

  ## Response
    - 200: Returns updated user data
    - 400: Invalid parameters
    - 401: User not authenticated
  """
  def update(conn, params) do
    user = conn.assigns.current_user
    allowed_params = Map.take(params, ["name", "email"])

    case Accounts.update_user(user, allowed_params) do
      {:ok, updated_user} ->
        conn
        |> put_status(:ok)
        |> render(:show, user: updated_user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: DailyReportsWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end

  operation(:create,
    summary: "Create User",
    description:
      "Creates a new user. Requires Master or Manager role. Managers cannot create Master role users.",
    request_body: {
      "User attributes",
      "application/json",
      Schemas.CreateUserRequest,
      required: true
    },
    responses: [
      created: {"Success", "application/json", Schemas.UserResponse},
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
  Creates a new user.

  Only Master and Manager role users can create new users.
  Manager users cannot create Master role users.

  ## Parameters
    - email: User's email (required)
    - password: User's password (required)
    - name: User's name (optional)
    - role: User's role (optional, defaults to "Collaborator")

  ## Response
    - 201: Returns created user data
    - 400: Invalid parameters
    - 401: User not authenticated
    - 403: Insufficient permissions (Manager trying to create Master)
    - 422: Validation errors
  """
  def create(conn, params) do
    current_user = conn.assigns.current_user
    requested_role = Map.get(params, "role", "Collaborator")

    # Managers cannot create Master users
    if current_user.role == "Manager" && requested_role == "Master" do
      conn
      |> put_status(:forbidden)
      |> json(%{errors: %{detail: "Managers cannot create Master role users"}})
    else
      case Accounts.create_user(params) do
        {:ok, user} ->
          conn
          |> put_status(:created)
          |> render(:show, user: user)

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(json: DailyReportsWeb.ChangesetJSON)
          |> render(:error, changeset: changeset)
      end
    end
  end
end
