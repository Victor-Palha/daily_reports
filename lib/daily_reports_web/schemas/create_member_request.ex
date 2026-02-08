defmodule DailyReportsWeb.Schemas.CreateMemberRequest do
  @moduledoc """
  OpenAPI schema for create member request.
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
    title: "CreateMemberRequest",
    description: "Request to add a member to a project",
    type: :object,
    properties: %{
      project_id: %Schema{
        type: :string,
        format: :uuid,
        description: "Project ID"
      },
      user_id: %Schema{
        type: :string,
        format: :uuid,
        description: "User ID"
      },
      role: %Schema{
        type: :string,
        enum: @roles,
        description: "Member role in the project"
      }
    },
    required: [:project_id, :user_id, :role],
    example: %{
      "project_id" => "9f8e7d6c-5b4a-3c2d-1e0f-9a8b7c6d5e4f",
      "user_id" => "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d",
      "role" => "Backend Developer"
    }
  })
end
