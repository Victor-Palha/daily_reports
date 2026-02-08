defmodule DailyReportsWeb.Schemas.Project do
  @moduledoc """
  OpenAPI schema for Project entity.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Project",
    description: "A project in the system",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid, description: "Project ID"},
      identifier: %Schema{
        type: :string,
        description: "Project identifier in format XX-YYYY-NN (e.g., VO-2026-01)",
        pattern: "^[A-Z]{2,4}-\\d{4}-\\d+$"
      },
      name: %Schema{type: :string, description: "Project name"},
      description: %Schema{type: :string, nullable: true, description: "Project description"},
      is_active: %Schema{type: :boolean, description: "Whether project is active"},
      parent_id: %Schema{
        type: :string,
        format: :uuid,
        nullable: true,
        description: "Parent project ID for child projects"
      },
      deactivated_at: %Schema{
        type: :string,
        format: :"date-time",
        nullable: true,
        description: "When the project was deactivated"
      },
      deactivated_by: %Schema{
        type: :string,
        format: :uuid,
        nullable: true,
        description: "User who deactivated the project"
      },
      created_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "Project creation timestamp"
      },
      updated_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "Project last update timestamp"
      }
    },
    required: [:id, :identifier, :name, :is_active, :created_at, :updated_at],
    example: %{
      "id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
      "identifier" => "VO-2026-01",
      "name" => "Project Alpha",
      "description" => "Main project for development",
      "is_active" => true,
      "parent_id" => nil,
      "deactivated_at" => nil,
      "deactivated_by" => nil,
      "created_at" => "2026-02-08T03:00:00Z",
      "updated_at" => "2026-02-08T03:00:00Z"
    }
  })
end
