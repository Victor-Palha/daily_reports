defmodule DailyReportsWeb.Schemas.Member do
  @moduledoc """
  OpenAPI schema for Member entity.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  @roles [
    "Backend Developer",
    "Frontend Developer",
    "Full Stack Developer",
    "Mobile Developer",
    "QA Engineer",
    "DevOps Engineer",
    "Tech Lead",
    "Product Owner",
    "Product Manager",
    "Scrum Master",
    "UI/UX Designer",
    "Data Engineer",
    "Data Scientist",
    "Solution Architect",
    "Business Analyst",
    "Security Engineer"
  ]

  OpenApiSpex.schema(%{
    title: "Member",
    description: "A project member",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid, description: "Member ID"},
      role: %Schema{
        type: :string,
        enum: @roles,
        description: "Member role in the project"
      },
      project_id: %Schema{type: :string, format: :uuid, description: "Project ID"},
      user_id: %Schema{type: :string, format: :uuid, description: "User ID"},
      project: %Schema{
        type: :object,
        nullable: true,
        description: "Project details (when preloaded)",
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          identifier: %Schema{type: :string},
          name: %Schema{type: :string},
          is_active: %Schema{type: :boolean}
        }
      },
      user: %Schema{
        type: :object,
        nullable: true,
        description: "User details (when preloaded)",
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          name: %Schema{type: :string},
          email: %Schema{type: :string},
          role: %Schema{type: :string}
        }
      },
      created_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "Member creation timestamp"
      }
    },
    required: [:id, :role, :project_id, :user_id, :created_at],
    example: %{
      "id" => "123e4567-e89b-12d3-a456-426614174000",
      "role" => "Backend Developer",
      "project_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
      "user_id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "project" => %{
        "id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
        "identifier" => "VO-2026-01",
        "name" => "Project Alpha",
        "is_active" => true
      },
      "user" => %{
        "id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
        "name" => "John Doe",
        "email" => "john@example.com",
        "role" => "Collaborator"
      },
      "created_at" => "2026-02-08T03:00:00Z"
    }
  })
end
