defmodule DailyReportsWeb.Schemas.ErrorResponse do
  @moduledoc """
  OpenAPI schema for error response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Error response",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        properties: %{
          detail: %Schema{type: :string, description: "Error message"}
        }
      }
    },
    required: [:errors]
  })
end
