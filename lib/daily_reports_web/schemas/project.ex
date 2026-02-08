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
      },
      parent: %Schema{
        type: :object,
        nullable: true,
        description: "Parent project details (when preloaded)",
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          identifier: %Schema{type: :string},
          name: %Schema{type: :string},
          is_active: %Schema{type: :boolean}
        }
      },
      children: %Schema{
        type: :array,
        description: "List of child projects (when preloaded)",
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            identifier: %Schema{type: :string},
            name: %Schema{type: :string},
            is_active: %Schema{type: :boolean}
          }
        }
      },
      members: %Schema{
        type: :array,
        description: "List of project members (when preloaded)",
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            role: %Schema{type: :string},
            user_id: %Schema{type: :string, format: :uuid},
            project_id: %Schema{type: :string, format: :uuid},
            created_at: %Schema{type: :string, format: :"date-time"}
          }
        }
      },
      reports: %Schema{
        type: :array,
        description: "List of project reports (when preloaded)",
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            title: %Schema{type: :string},
            summary: %Schema{type: :string},
            report_date: %Schema{type: :string, format: :date},
            achievements: %Schema{type: :string},
            impediments: %Schema{type: :string},
            next_steps: %Schema{type: :string},
            created_by_id: %Schema{type: :string, format: :uuid},
            created_at: %Schema{type: :string, format: :"date-time"}
          }
        }
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
      "updated_at" => "2026-02-08T03:00:00Z",
      "parent" => nil,
      "children" => [
        %{
          "id" => "8e7d6c5b-4a3c-2d1e-0f9a-8b7c6d5e4f3",
          "identifier" => "VO-2026-02",
          "name" => "Subproject A",
          "is_active" => true,
          "description" => "Subproject for frontend development",
          "parent_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
          "deactivated_at" => nil,
          "deactivated_by" => nil,
          "created_at" => "2026-02-08T04:00:00Z",
          "updated_at" => "2026-02-08T04:00:00Z"
        }
      ],
      "members" => [
        %{
          "id" => "123e4567-e89b-12d3-a456-426614174000",
          "role" => "Backend Developer",
          "user_id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
          "project_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
          "created_at" => "2026-02-08T05:00:00Z"
        }
      ]
    }
  })
end
