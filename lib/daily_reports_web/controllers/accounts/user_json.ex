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
  Renders a list of users.
  """
  def index(%{users: users}) do
    %{
      data: Enum.map(users, &user_data/1)
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
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      is_active: user.is_active,
      created_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
