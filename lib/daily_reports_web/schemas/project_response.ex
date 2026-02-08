defmodule DailyReportsWeb.Schemas.ProjectResponse do
  @moduledoc """
  OpenAPI schema for single project response.
  """
  require OpenApiSpex
  alias DailyReportsWeb.Schemas.Project

  OpenApiSpex.schema(%{
    title: "ProjectResponse",
    description: "Single project response",
    type: :object,
    properties: %{
      data: Project
    },
    required: [:data]
  })
end
