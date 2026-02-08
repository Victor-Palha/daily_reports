defmodule DailyReportsWeb.Reports.ReportJSON do
  @moduledoc """
  Renders Report data in JSON format.
  """

  alias DailyReports.Reports.Report

  @doc """
  Renders a list of reports.
  """
  def index(%{data: reports, meta: meta}) do
    %{
      data: Enum.map(reports, &report_data/1),
      meta: meta
    }
  end

  @doc """
  Renders a single report.
  """
  def show(%{report: report}) do
    %{data: report_data(report)}
  end

  defp report_data(%Report{} = report) do
    base = %{
      id: report.id,
      title: report.title,
      summary: report.summary,
      report_date: report.report_date,
      achievements: report.achievements,
      impediments: report.impediments,
      next_steps: report.next_steps,
      project_id: report.project_id,
      created_by_id: report.created_by_id,
      inserted_at: report.inserted_at,
      updated_at: report.updated_at
    }

    base =
      if Ecto.assoc_loaded?(report.project) do
        Map.put(base, :project, %{
          id: report.project.id,
          name: report.project.name,
          description: report.project.description
        })
      else
        base
      end

    if Ecto.assoc_loaded?(report.created_by) do
      created_by = report.created_by

      creator_data = %{
        id: created_by.id,
        role: created_by.role
      }

      creator_data =
        if Ecto.assoc_loaded?(created_by.user) do
          Map.merge(creator_data, %{
            user: %{
              id: created_by.user.id,
              name: created_by.user.name,
              email: created_by.user.email
            }
          })
        else
          creator_data
        end

      Map.put(base, :created_by, creator_data)
    else
      base
    end
  end
end
