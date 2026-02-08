defmodule DailyReportsWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification for Daily Reports API.
  """

  alias OpenApiSpex.{Info, OpenApi, Paths, Server, Components, SecurityScheme}
  alias DailyReportsWeb.{Endpoint, Router}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Daily Reports API",
        version: "1.0.0",
        description: "API for managing daily reports, users, projects, and members"
      },
      servers: [
        Server.from_endpoint(Endpoint)
      ],
      paths: Paths.from_router(Router),
      components: %Components{
        securitySchemes: %{
          "cookieAuth" => %SecurityScheme{
            type: "apiKey",
            in: "cookie",
            name: "access_token",
            description: "JWT access token stored in HTTP-only cookie"
          }
        }
      }
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
