defmodule DailyReports.Projects.Member do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles [
    "Backend Developer",
    "Frontend Developer",
    "Full Stack Developer",
    "Mobile Developer",
    "QA Engineer",
    "DevOps Engineer",
    "Tech Lead",
    "Product Owner",
    "Product Manager",
    "Scrum Master",
    "UI/UX Designer",
    "Data Engineer",
    "Data Scientist",
    "Solution Architect",
    "Business Analyst",
    "Security Engineer"
  ]

  schema "members" do
    field :role, :string

    belongs_to :project, DailyReports.Projects.Project, foreign_key: :project_id, references: :id
    belongs_to :user, DailyReports.Accounts.User, foreign_key: :user_id, references: :id

    has_many :reports, DailyReports.Reports.Report, foreign_key: :created_by_id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Returns the list of valid member roles.
  """
  def roles, do: @roles

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> validate_role()
    |> unique_constraint([:project_id, :user_id],
      name: :members_project_id_user_id_index,
      message: "user is already a member of this project"
    )
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :role, @roles,
      message: "must be one of: #{Enum.join(@roles, ", ")}"
    )
  end
end
