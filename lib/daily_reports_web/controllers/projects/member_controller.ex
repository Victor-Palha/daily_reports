defmodule DailyReportsWeb.Projects.MemberController do
  use DailyReportsWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias DailyReports.Projects
  alias DailyReportsWeb.Schemas

  action_fallback DailyReportsWeb.FallbackController

  tags(["Members"])

  plug :authorize_create when action in [:create]

  defp authorize_create(conn, _opts) do
    DailyReportsWeb.Plugs.AuthorizeUser.call(
      conn,
      DailyReportsWeb.Plugs.AuthorizeUser.init(roles: ["Master", "Manager"])
    )
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
end
