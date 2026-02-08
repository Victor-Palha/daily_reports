defmodule DailyReportsWeb.Accounts.AuthJSON do
  @moduledoc """
  JSON presenter for authentication responses.
  """

  @doc """
  Renders authentication response with tokens.
  """
  def auth(%{user: user, access_token: access_token, refresh_token: refresh_token}) do
    %{
      data: %{
        user: user_data(user),
        access_token: access_token,
        refresh_token: refresh_token
      }
    }
  end

  @doc """
  Renders token refresh response.
  """
  def refresh(%{access_token: access_token, refresh_token: refresh_token}) do
    %{
      data: %{
        access_token: access_token,
        refresh_token: refresh_token
      }
    }
  end

  @doc """
  Renders logout response.
  """
  def logout(_params) do
    %{
      data: %{
        message: "Successfully logged out"
      }
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
      is_active: user.is_active
    }
  end
end
