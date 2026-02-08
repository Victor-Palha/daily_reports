defmodule DailyReportsWeb.Schemas.MemberResponse do
  @moduledoc """
  OpenAPI schema for single member response.
  """
  require OpenApiSpex
  alias DailyReportsWeb.Schemas.Member

  OpenApiSpex.schema(%{
    title: "MemberResponse",
    description: "Single member response",
    type: :object,
    properties: %{
      data: Member
    },
    required: [:data]
  })
end
