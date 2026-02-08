defmodule DailyReportsWeb.Schemas.LoginRequest do
  @moduledoc """
  OpenAPI schema for login request.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "LoginRequest",
    description: "Login credentials",
    type: :object,
    properties: %{
      email: %Schema{type: :string, format: :email, description: "User email"},
      password: %Schema{type: :string, description: "User password"}
    },
    required: [:email, :password],
    example: %{
      "email" => "user@example.com",
      "password" => "Password123!"
    }
  })
end
