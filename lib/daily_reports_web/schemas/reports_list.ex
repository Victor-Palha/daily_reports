defmodule DailyReportsWeb.Schemas.ReportsList do
  @moduledoc """
  OpenAPI schema for paginated list of reports.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias DailyReportsWeb.Schemas.Report

  OpenApiSpex.schema(%{
    title: "ReportsList",
    description: "Paginated list of reports",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: Report},
      meta: %Schema{
        type: :object,
        properties: %{
          total_count: %Schema{type: :integer, description: "Total number of reports"},
          page: %Schema{type: :integer, description: "Current page number"},
          page_size: %Schema{type: :integer, description: "Number of items per page"},
          total_pages: %Schema{type: :integer, description: "Total number of pages"}
        }
      }
    },
    required: [:data, :meta]
  })
end
