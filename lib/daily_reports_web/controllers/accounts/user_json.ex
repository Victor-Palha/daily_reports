defmodule DailyReportsWeb.Accounts.UserJSON do
  @moduledoc """
  JSON presenter for user responses.
  """

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{
      data: user_data(user)
    }
  end

  @doc """
  Renders a paginated list of users with metadata.
  """
  def index(%{
        users: users,
        total_count: total_count,
        page: page,
        page_size: page_size,
        total_pages: total_pages
      }) do
    %{
      data: Enum.map(users, &user_data/1),
      meta: %{
        total_count: total_count,
        page: page,
        page_size: page_size,
        total_pages: total_pages
      }
    }
  end

  @doc """
  Renders user creation response.
  """
  def create(%{user: user}) do
    %{
      data: user_data(user)
    }
  end

  @doc """
  Renders error response.
  """
  def error(%{message: message}) do
    %{
      errors: %{
        detail: message
      }
    }
  end

  defp user_data(user) do
    base_data = %{
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      is_active: user.is_active,
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }

    base_data
    |> maybe_add_created_by(user)
    |> maybe_add_members(user)
    |> maybe_add_projects(user)
  end

  defp maybe_add_created_by(data, %{created_by_user: created_by})
       when not is_nil(created_by) do
    if Ecto.assoc_loaded?(created_by) do
      Map.put(data, :created_by, %{
        id: created_by.id,
        name: created_by.name,
        email: created_by.email
      })
    else
      data
    end
  end

  defp maybe_add_created_by(data, _user), do: data

  defp maybe_add_members(data, %{members: members}) do
    if Ecto.assoc_loaded?(members) && length(members) > 0 do
      Map.put(
        data,
        :members,
        Enum.map(members, fn member ->
          %{
            id: member.id,
            role: member.role,
            project_id: member.project_id,
            created_at: member.inserted_at
          }
        end)
      )
    else
      data
    end
  end

  defp maybe_add_members(data, _user), do: data

  defp maybe_add_projects(data, %{projects: projects}) do
    if Ecto.assoc_loaded?(projects) && length(projects) > 0 do
      Map.put(
        data,
        :projects,
        Enum.map(projects, fn project ->
          %{
            id: project.id,
            identifier: project.identifier,
            name: project.name,
            is_active: project.is_active
          }
        end)
      )
    else
      data
    end
  end

  defp maybe_add_projects(data, _user), do: data
end
