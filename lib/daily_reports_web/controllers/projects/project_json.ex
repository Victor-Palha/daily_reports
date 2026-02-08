defmodule DailyReportsWeb.Projects.ProjectJSON do
  @moduledoc """
  Renders Project data in JSON format.
  """

  alias DailyReports.Projects.Project

  @doc """
  Renders a single project.
  """
  def show(%{project: project}) do
    %{data: project_data(project)}
  end

  defp project_data(%Project{} = project) do
    %{
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
  end
end
