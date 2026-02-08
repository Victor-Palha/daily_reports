defmodule DailyReportsWeb.Schemas.UserResponse do
  @moduledoc """
  OpenAPI schema for single user response.
  """
  require OpenApiSpex
  alias DailyReportsWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UserResponse",
    description: "Single user response",
    type: :object,
    properties: %{
      data: User
    },
    required: [:data]
  })
end
