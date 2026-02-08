defmodule DailyReports.Report do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reports" do
    field :title, :string
    field :report_date, :date
    field :summary, :string
    field :achievements, :string
    field :impediments, :string
    field :next_steps, :string

    belongs_to :project, DailyReports.Project, foreign_key: :project_id, references: :id
    belongs_to :created_by, DailyReports.Member, foreign_key: :created_by_id, references: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:title, :report_date, :summary, :achievements, :impediments, :next_steps])
    |> validate_required([:title, :report_date])
    |> put_default_report_date()
    |> validate_report_date()
  end

  defp put_default_report_date(changeset) do
    if get_field(changeset, :report_date) do
      changeset
    else
      put_change(changeset, :report_date, Date.utc_today())
    end
  end

  defp validate_report_date(changeset) do
    changeset
    |> validate_required([:report_date])
  end
end
