defmodule DailyReports.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias DailyReports.Repo
  alias DailyReports.Projects.Project
  alias DailyReports.Projects.Member
  alias DailyReports.Accounts.User

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

  @doc """
  Creates a member for a project.

  Validates that both the project and user exist before creating the member.

  ## Examples

      iex> create_member(%{project_id: project_id, user_id: user_id, role: "Backend Developer"})
      {:ok, %Member{}}

      iex> create_member(%{project_id: invalid_id, user_id: user_id, role: "Backend Developer"})
      {:error, "Project does not exist"}

  """
  def create_member(attrs \\ %{}) do
    case validate_member_associations(attrs) do
      {:ok, validated_attrs} ->
        %Member{}
        |> Member.changeset(validated_attrs)
        |> Repo.insert()

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a single member.

  Returns nil if the Member does not exist.
  """
  def get_member(id), do: Repo.get(Member, id)

  @doc """
  Lists members of a project with filtering and pagination.

  ## Parameters
    - project_id: Project ID (required)
    - role: Filter by role (optional)
    - page: Page number (default: 1)
    - page_size: Number of items per page (default: 20, max: 100)

  ## Examples

      iex> list_members(%{"project_id" => project_id})
      %{data: [%Member{}], meta: %{total_count: 5, page: 1, page_size: 20, total_pages: 1}}

  """
  def list_members(params) do
    project_id = Map.get(params, "project_id")
    role = Map.get(params, "role")
    page = Map.get(params, "page", "1") |> String.to_integer()
    page_size = min(Map.get(params, "page_size", "20") |> String.to_integer(), 100)

    query =
      Member
      |> where([m], m.project_id == ^project_id)
      |> order_by([m], desc: m.inserted_at)

    query =
      if role do
        where(query, [m], m.role == ^role)
      else
        query
      end

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_count / page_size)

    members =
      query
      |> limit(^page_size)
      |> offset(^((page - 1) * page_size))
      |> preload([:project, :user])
      |> Repo.all()

    %{
      data: members,
      meta: %{
        total_count: total_count,
        page: page,
        page_size: page_size,
        total_pages: total_pages
      }
    }
  end

  @doc """
  Checks if a user is a member of a project.

  ## Examples

      iex> is_member?(project_id, user_id)
      true

  """
  def is_member?(project_id, user_id) do
    Member
    |> where([m], m.project_id == ^project_id and m.user_id == ^user_id)
    |> Repo.exists?()
  end

  @doc """
  Preloads associations for a member or list of members.
  """
  def preload_members(member_or_members) do
    Repo.preload(member_or_members, [:project, :user])
  end

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

  defp validate_member_associations(%{"project_id" => project_id, "user_id" => user_id} = attrs)
       when not is_nil(project_id) and not is_nil(user_id) do
    cond do
      is_nil(get_project(project_id)) ->
        {:error, "Project does not exist"}

      is_nil(Repo.get(User, user_id)) ->
        {:error, "User does not exist"}

      true ->
        {:ok, attrs}
    end
  end

  defp validate_member_associations(attrs) when is_map(attrs) do
    cond do
      not Map.has_key?(attrs, "project_id") ->
        {:error, "Project ID is required"}

      not Map.has_key?(attrs, "user_id") ->
        {:error, "User ID is required"}

      true ->
        {:ok, attrs}
    end
  end
end
