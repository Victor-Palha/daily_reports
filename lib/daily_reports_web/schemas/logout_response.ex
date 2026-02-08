defmodule DailyReportsWeb.Schemas.LogoutResponse do
  @moduledoc """
  OpenAPI schema for logout response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LogoutResponse",
    description: "Logout response",
    type: :object,
    properties: %{
      data: %Schema{
        type: :object,
        properties: %{
          message: %Schema{type: :string}
        }
      }
    }
  })
end
