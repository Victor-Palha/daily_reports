defmodule DailyReports.Repo do
  use Ecto.Repo,
    otp_app: :daily_reports,
    adapter: Ecto.Adapters.Postgres
end
