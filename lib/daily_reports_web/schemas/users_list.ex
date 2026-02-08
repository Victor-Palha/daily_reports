defmodule DailyReportsWeb.Schemas.UsersList do
  @moduledoc """
  OpenAPI schema for paginated list of users.
  """
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias DailyReportsWeb.Schemas.User

  OpenApiSpex.schema(%{
    title: "UsersList",
    description: "Paginated list of users",
    type: :object,
    properties: %{
      data: %Schema{type: :array, items: User},
      meta: %Schema{
        type: :object,
        properties: %{
          total_count: %Schema{type: :integer, description: "Total number of users"},
          page: %Schema{type: :integer, description: "Current page number"},
          page_size: %Schema{type: :integer, description: "Number of items per page"},
          total_pages: %Schema{type: :integer, description: "Total number of pages"}
        }
      }
    },
    required: [:data, :meta]
  })
end
