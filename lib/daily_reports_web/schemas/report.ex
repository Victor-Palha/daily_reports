defmodule DailyReportsWeb.Schemas.Report do
  @moduledoc """
  OpenAPI schema for Report.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "Report",
    description: "A daily report for a project",
    type: :object,
    properties: %{
      id: %Schema{type: :string, format: :uuid, description: "Report ID"},
      title: %Schema{type: :string, description: "Report title"},
      summary: %Schema{type: :string, description: "Report summary"},
      report_date: %Schema{type: :string, format: :date, description: "Report date"},
      achievements: %Schema{type: :string, description: "Achievements", nullable: true},
      impediments: %Schema{type: :string, description: "Impediments", nullable: true},
      next_steps: %Schema{type: :string, description: "Next steps", nullable: true},
      project_id: %Schema{type: :string, format: :uuid, description: "Project ID"},
      created_by_id: %Schema{
        type: :string,
        format: :uuid,
        description: "Member ID who created the report"
      },
      project: %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          name: %Schema{type: :string},
          description: %Schema{type: :string, nullable: true}
        }
      },
      created_by: %Schema{
        type: :object,
        properties: %{
          id: %Schema{type: :string, format: :uuid},
          role: %Schema{type: :string},
          user: %Schema{
            type: :object,
            properties: %{
              id: %Schema{type: :string, format: :uuid},
              name: %Schema{type: :string},
              email: %Schema{type: :string}
            }
          }
        }
      },
      inserted_at: %Schema{type: :string, format: :"date-time", description: "Creation timestamp"},
      updated_at: %Schema{
        type: :string,
        format: :"date-time",
        description: "Last update timestamp"
      }
    },
    required: [:id, :title, :summary, :report_date, :project_id, :created_by_id]
  })
end
