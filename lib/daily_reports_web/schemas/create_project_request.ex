defmodule DailyReportsWeb.Schemas.CreateProjectRequest do
  @moduledoc """
  OpenAPI schema for create project request.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CreateProjectRequest",
    description: "Request to create a new project",
    type: :object,
    properties: %{
      identifier: %Schema{
        type: :string,
        description: "Project identifier in format XX-YYYY-NN (e.g., VO-2026-01)",
        pattern: "^[A-Z]{2,4}-\\d{4}-\\d+$"
      },
      name: %Schema{type: :string, description: "Project name"},
      description: %Schema{type: :string, description: "Project description"},
      parent_id: %Schema{
        type: :string,
        format: :uuid,
        description: "Parent project ID to create a child project"
      }
    },
    required: [:identifier, :name],
    example: %{
      "identifier" => "VO-2026-02",
      "name" => "New Project",
      "description" => "A new project description",
      "parent_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f"
    }
  })
end
