defmodule DailyReportsWeb.Schemas.ProjectsList do
  @moduledoc """
  OpenAPI schema for paginated list of projects.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ProjectsList",
    description: "Paginated list of projects",
    type: :object,
    properties: %{
      data: %Schema{
        type: :array,
        items: %Schema{
          type: :object,
          properties: %{
            id: %Schema{type: :string, format: :uuid},
            identifier: %Schema{type: :string},
            name: %Schema{type: :string},
            description: %Schema{type: :string, nullable: true},
            is_active: %Schema{type: :boolean},
            parent_id: %Schema{type: :string, format: :uuid, nullable: true},
            created_at: %Schema{type: :string, format: :"date-time"},
            updated_at: %Schema{type: :string, format: :"date-time"}
          }
        }
      },
      meta: %Schema{
        type: :object,
        properties: %{
          total_count: %Schema{type: :integer, description: "Total number of projects"},
          page: %Schema{type: :integer, description: "Current page number"},
          page_size: %Schema{type: :integer, description: "Number of items per page"},
          total_pages: %Schema{type: :integer, description: "Total number of pages"}
        }
      }
    },
    required: [:data, :meta]
  })
end
