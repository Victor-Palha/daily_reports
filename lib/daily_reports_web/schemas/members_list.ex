defmodule DailyReportsWeb.Schemas.MembersList do
  @moduledoc """
  OpenAPI schema for paginated list of members.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias DailyReportsWeb.Schemas.Member

  OpenApiSpex.schema(%{
    title: "MembersList",
    description: "Paginated list of project members",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: Member},
      meta: %Schema{
        type: :object,
        properties: %{
          total_count: %Schema{type: :integer, description: "Total number of members"},
          page: %Schema{type: :integer, description: "Current page number"},
          page_size: %Schema{type: :integer, description: "Number of items per page"},
          total_pages: %Schema{type: :integer, description: "Total number of pages"}
        }
      }
    },
    required: [:data, :meta]
  })
end
