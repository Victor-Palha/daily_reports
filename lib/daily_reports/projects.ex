defmodule DailyReports.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias DailyReports.Repo
  alias DailyReports.Projects.Project

  @doc """
  Creates a project.

  If parent_id is provided, validates that the parent project exists and is active.

  ## Examples

      iex> create_project(%{identifier: "VO-2026-01", name: "Project"})
      {:ok, %Project{}}

      iex> create_project(%{identifier: "VO-2026-02", name: "Sub Project", parent_id: parent_id})
      {:ok, %Project{}}

      iex> create_project(%{identifier: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    case validate_parent_id(attrs) do
      {:ok, validated_attrs} ->
        %Project{}
        |> Project.changeset(validated_attrs)
        |> Repo.insert()

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Gets a single project.

  Returns nil if the Project does not exist.

  ## Examples

      iex> get_project(123)
      %Project{}

      iex> get_project(456)
      nil

  """
  def get_project(id), do: Repo.get(Project, id)

  # Private functions

  defp validate_parent_id(%{"parent_id" => parent_id} = attrs) when not is_nil(parent_id) do
    case get_project(parent_id) do
      %Project{is_active: true} = _parent ->
        {:ok, attrs}

      %Project{is_active: false} ->
        {:error, "Parent project is not active"}

      nil ->
        {:error, "Parent project does not exist"}
    end
  end

  defp validate_parent_id(attrs), do: {:ok, attrs}
end
