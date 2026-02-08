defmodule DailyReportsWeb.Schemas.AuthResponse do
  @moduledoc """
  OpenAPI schema for authentication response with tokens.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias DailyReportsWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "AuthResponse",
    description: "Authentication response with tokens",
    type: :object,
    properties: %{
      data: %Schema{
        type: :object,
        properties: %{
          user: User,
          access_token: %Schema{type: :string, description: "JWT access token"},
          refresh_token: %Schema{type: :string, description: "JWT refresh token"}
        },
        required: [:user, :access_token, :refresh_token]
      }
    },
    required: [:data]
  })
end
