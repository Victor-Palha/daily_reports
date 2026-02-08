defmodule DailyReportsWeb.Accounts.UserController do
  use DailyReportsWeb, :controller

  alias DailyReports.Accounts

  action_fallback DailyReportsWeb.FallbackController

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
end
