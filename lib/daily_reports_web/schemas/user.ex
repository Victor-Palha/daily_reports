defmodule DailyReportsWeb.Schemas.User do
  @moduledoc """
  OpenAPI schema for User entity.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "User",
    description: "A user in the system",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid, description: "User ID"},
      email: %Schema{type: :string, format: :email, description: "User email address"},
      name: %Schema{type: :string, description: "User name"},
      role: %Schema{
        type: :string,
        enum: ["Master", "Manager", "Collaborator"],
        description: "User role"
      },
      is_active: %Schema{type: :boolean, description: "Whether user is active"},
      created_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "User creation timestamp"
      },
      updated_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "User last update timestamp"
      },
      created_by: %Schema{
        type: :object,
        nullable: true,
        description: "User who created this user",
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          name: %Schema{type: :string},
          email: %Schema{type: :string}
        }
      },
      members: %Schema{
        type: :array,
        description: "User's project memberships",
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            role: %Schema{type: :string},
            project_id: %Schema{type: :string, format: :uuid},
            created_at: %Schema{type: :string, format: :"date-time"}
          }
        }
      },
      projects: %Schema{
        type: :array,
        description: "User's projects",
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            identifier: %Schema{type: :string},
            name: %Schema{type: :string},
            is_active: %Schema{type: :boolean}
          }
        }
      }
    },
    required: [:id, :email, :name, :role, :is_active, :created_at, :updated_at],
    example: %{
      "id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "email" => "user@example.com",
      "name" => "John Doe",
      "role" => "Collaborator",
      "is_active" => true,
      "created_by" => %{
        "id" => "f6e5d4c3-b2a1-4c5d-8e9f-0a1b2c3d4e5f",
        "name" => "Admin User",
        "email" => "admin@example.com"
      },
      "members" => [
        %{
          "id" => "123e4567-e89b-12d3-a456-426614174000",
          "role" => "Developer",
          "project_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
          "created_at" => "2026-01-15T12:00:00Z"
        }
      ],
      "projects" => [
        %{
          "id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
          "identifier" => "PRJ-2026-0001",
          "name" => "Project Alpha",
          "is_active" => true
        }
      ],
      "created_at" => "2026-02-08T03:00:00Z",
      "updated_at" => "2026-02-08T03:00:00Z"
    }
  })
end
