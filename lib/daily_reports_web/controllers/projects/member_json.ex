defmodule DailyReportsWeb.Projects.MemberJSON do
  @moduledoc """
  Renders Member data in JSON format.
  """

  alias DailyReports.Projects.Member

  @doc """
  Renders a single member.
  """
  def show(%{member: member}) do
    %{data: member_data(member)}
  end

  defp member_data(%Member{} = member) do
    base = %{
      id: member.id,
      role: member.role,
      project_id: member.project_id,
      user_id: member.user_id,
      created_at: member.inserted_at
    }

    base
    |> maybe_add_project(member)
    |> maybe_add_user(member)
  end

  defp maybe_add_project(data, %Member{project: %Ecto.Association.NotLoaded{}}), do: data

  defp maybe_add_project(data, %Member{project: project}) when not is_nil(project) do
    Map.put(data, :project, %{
      id: project.id,
      identifier: project.identifier,
      name: project.name,
      is_active: project.is_active
    })
  end

  defp maybe_add_project(data, _), do: data

  defp maybe_add_user(data, %Member{user: %Ecto.Association.NotLoaded{}}), do: data

  defp maybe_add_user(data, %Member{user: user}) when not is_nil(user) do
    Map.put(data, :user, %{
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    })
  end

  defp maybe_add_user(data, _), do: data
end
