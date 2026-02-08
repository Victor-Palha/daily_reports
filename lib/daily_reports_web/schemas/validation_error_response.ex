defmodule DailyReportsWeb.Schemas.ValidationErrorResponse do
  @moduledoc """
  OpenAPI schema for validation error response.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ValidationErrorResponse",
    description: "Validation error response",
    type: :object,
    properties: %{
      errors: %Schema{
        type: :object,
        additionalProperties: %Schema{
          oneOf: [
            %Schema{type: :string},
            %Schema{type: :array, items: %Schema{type: :string}}
          ]
        }
      }
    }
  })
end
