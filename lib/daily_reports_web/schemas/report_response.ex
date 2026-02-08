defmodule DailyReportsWeb.Schemas.ReportResponse do
  @moduledoc """
  OpenAPI schema for Report response.
  """
  require OpenApiSpex
  alias DailyReportsWeb.Schemas.Report

  OpenApiSpex.schema(%{
    title: "ReportResponse",
    description: "Response containing report data",
    type: :object,
    properties: %{
      data: Report
    },
    required: [:data]
  })
end
