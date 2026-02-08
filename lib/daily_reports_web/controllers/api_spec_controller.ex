defmodule DailyReportsWeb.ApiSpecController do
  use DailyReportsWeb, :controller

  alias OpenApiSpex.Plug.PutApiSpec

  plug PutApiSpec, module: DailyReportsWeb.ApiSpec

  def spec(conn, _params) do
    json(conn, DailyReportsWeb.ApiSpec.spec())
  end
end
