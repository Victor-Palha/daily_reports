defmodule DailyReportsWeb.Projects.ProjectJSON do
  @moduledoc """
  Renders Project data in JSON format.
  """

  alias DailyReports.Projects.Project

  @doc """
  Renders a list of projects.
  """
  def index(%{data: projects, meta: meta}) do
    %{
      data: Enum.map(projects, &project_summary/1),
      meta: meta
    }
  end

  @doc """
  Renders a single project.
  """
  def show(%{project: project}) do
    %{data: project_data(project)}
  end

  defp project_summary(%Project{} = project) do
    %{
      id: project.id,
      identifier: project.identifier,
      name: project.name,
      description: project.description,
      is_active: project.is_active,
      parent_id: project.parent_id,
      created_at: project.inserted_at,
      updated_at: project.updated_at
    }
  end

  defp project_data(%Project{} = project) do
    base = %{
      id: project.id,
      identifier: project.identifier,
      name: project.name,
      description: project.description,
      is_active: project.is_active,
      parent_id: project.parent_id,
      deactivated_at: project.deactivated_at,
      deactivated_by: project.deactivated_by,
      created_at: project.inserted_at,
      updated_at: project.updated_at
    }

    base =
      if Ecto.assoc_loaded?(project.reports) do
        Map.put(base, :reports, Enum.map(project.reports, &report_data/1))
      else
        base
      end

    base =
      if Ecto.assoc_loaded?(project.members) do
        Map.put(base, :members, Enum.map(project.members, &member_data/1))
      else
        base
      end

    if Ecto.assoc_loaded?(project.children) do
      Map.put(base, :children, Enum.map(project.children, &child_project_data/1))
    else
      base
    end
  end

  defp report_data(report) do
    base = %{
      id: report.id,
      title: report.title,
      summary: report.summary,
      report_date: report.report_date,
      achievements: report.achievements,
      impediments: report.impediments,
      next_steps: report.next_steps,
      created_by_id: report.created_by_id,
      created_at: report.inserted_at
    }

    if Ecto.assoc_loaded?(report.created_by) do
      member = report.created_by

      creator = %{
        id: member.id,
        role: member.role
      }

      creator =
        if Ecto.assoc_loaded?(member.user) do
          Map.put(creator, :user, %{
            id: member.user.id,
            name: member.user.name,
            email: member.user.email
          })
        else
          creator
        end

      Map.put(base, :created_by, creator)
    else
      base
    end
  end

  defp member_data(member) do
    base = %{
      id: member.id,
      role: member.role,
      user_id: member.user_id,
      created_at: member.inserted_at
    }

    if Ecto.assoc_loaded?(member.user) do
      Map.put(base, :user, %{
        id: member.user.id,
        name: member.user.name,
        email: member.user.email
      })
    else
      base
    end
  end

  defp child_project_data(child) do
    %{
      id: child.id,
      identifier: child.identifier,
      name: child.name,
      description: child.description,
      is_active: child.is_active,
      created_at: child.inserted_at
    }
  end
end
