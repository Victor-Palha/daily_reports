defmodule DailyReportsWeb.Schemas.CreateReportRequest do
  @moduledoc """
  OpenAPI schema for creating a report.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CreateReportRequest",
    description: "Request body for creating a report",
    type: :object,
    properties: %{
      project_id: %Schema{
        type: :string,
        format: :uuid,
        description: "Project ID (required)"
      },
      created_by_id: %Schema{
        type: :string,
        format: :uuid,
        description:
          "Member ID (required for Master/Manager, automatically set for Collaborators)"
      },
      title: %Schema{type: :string, description: "Report title (required)"},
      summary: %Schema{type: :string, description: "Report summary (required)"},
      report_date: %Schema{
        type: :string,
        format: :date,
        description: "Report date (optional, defaults to today)"
      },
      achievements: %Schema{type: :string, description: "Achievements (optional)"},
      impediments: %Schema{type: :string, description: "Impediments (optional)"},
      next_steps: %Schema{type: :string, description: "Next steps (optional)"}
    },
    required: [:project_id, :title, :summary],
    example: %{
      "project_id" => "123e4567-e89b-12d3-a456-426614174000",
      "title" => "Daily Progress Report",
      "summary" => "Completed user authentication module",
      "achievements" => "Implemented JWT tokens and refresh mechanism",
      "impediments" => "Database performance issue with large datasets",
      "next_steps" => "Optimize database queries and add caching"
    }
  })
end
