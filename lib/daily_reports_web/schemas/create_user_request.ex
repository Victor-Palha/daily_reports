defmodule DailyReportsWeb.Schemas.CreateUserRequest do
  @moduledoc """
  OpenAPI schema for create user request.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CreateUserRequest",
    description: "Request to create a new user",
    type: :object,
    properties: %{
      email: %Schema{type: :string, format: :email, description: "User email"},
      password: %Schema{
        type: :string,
        minLength: 8,
        maxLength: 72,
        description: "User password"
      },
      name: %Schema{type: :string, description: "User name"},
      role: %Schema{
        type: :string,
        enum: ["Master", "Manager", "Collaborator"],
        description: "User role",
        default: "Collaborator"
      }
    },
    required: [:email, :password],
    example: %{
      "email" => "newuser@example.com",
      "password" => "Password123!",
      "name" => "New User",
      "role" => "Collaborator"
    }
  })
end
