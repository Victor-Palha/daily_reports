defmodule DailyReportsWeb.Schemas.TokenResponse do
  @moduledoc """
  OpenAPI schema for token refresh response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TokenResponse",
    description: "Token refresh response",
    type: :object,
    properties: %{
      data: %Schema{
        type: :object,
        properties: %{
          access_token: %Schema{type: :string, description: "New JWT access token"},
          refresh_token: %Schema{type: :string, description: "New JWT refresh token"}
        },
        required: [:access_token, :refresh_token]
      }
    },
    required: [:data]
  })
end
