defmodule DailyReportsWeb.Schemas.UpdateUserRequest do
  @moduledoc """
  OpenAPI schema for update user request.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "UpdateUserRequest",
    description: "Request to update user profile",
    type: :object,
    properties: %{
      name: %Schema{type: :string, description: "User name"},
      email: %Schema{type: :string, format: :email, description: "User email"}
    },
    example: %{
      "name" => "Updated Name",
      "email" => "newemail@example.com"
    }
  })
end
