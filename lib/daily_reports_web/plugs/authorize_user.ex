defmodule DailyReportsWeb.Plugs.AuthorizeUser do
  @moduledoc """
  Plug for role-based authorization.

  This plug checks if the authenticated user has one of the required roles.

  ## Options
    - :roles - List of roles allowed to access the resource (required)

  ## Usage

      # In router - require Master or Manager role
      plug DailyReportsWeb.Plugs.AuthorizeUser, roles: ["Master", "Manager"]

      # In router - require only Master role
      plug DailyReportsWeb.Plugs.AuthorizeUser, roles: ["Master"]

  ## Requires
    - Must be used after AuthenticateUser plug (requires :current_user assign)
  """

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts) do
    roles = Keyword.get(opts, :roles, [])

    if Enum.empty?(roles) do
      raise ArgumentError, "AuthorizeUser plug requires :roles option"
    end

    %{roles: roles}
  end

  def call(conn, %{roles: allowed_roles}) do
    current_user = conn.assigns[:current_user]

    cond do
      is_nil(current_user) ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "Authentication required"}})
        |> halt()

      current_user.role in allowed_roles ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{errors: %{detail: "Insufficient permissions"}})
        |> halt()
    end
  end
end
