defmodule DailyReports.Project do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "projects" do
    field :identifier, :string
    field :name, :string
    field :description, :string
    field :is_active, :boolean, default: true
    field :deactivated_at, :utc_datetime

    belongs_to :parent, __MODULE__, foreign_key: :parent_id, references: :id

    belongs_to :deactivated_by_user, DailyReports.User,
      foreign_key: :deactivated_by,
      references: :id

    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :members, DailyReports.Member, foreign_key: :project_id
    has_many :users, through: [:members, :user]
    has_many :reports, DailyReports.Report, foreign_key: :project_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:identifier, :name, :description, :is_active, :parent_id, :deactivated_at])
    |> validate_required([:identifier, :name])
    |> validate_identifier()
    |> unique_constraint(:identifier)
  end

  @doc false
  def deactivation_changeset(project, attrs) do
    project
    |> cast(attrs, [:is_active, :deactivated_at, :deactivated_by])
    |> validate_required([:is_active])
    |> put_deactivated_at()
  end

  defp validate_identifier(changeset) do
    changeset
    |> validate_format(:identifier, ~r/^[A-Z]{2,4}-\d{4}-\d+$/,
      message: "must be in format: VO-2026-01 (Sigla-Ano-ID)"
    )
  end

  defp put_deactivated_at(changeset) do
    if get_change(changeset, :is_active) == false do
      put_change(changeset, :deactivated_at, DateTime.utc_now())
    else
      changeset
    end
  end
end
