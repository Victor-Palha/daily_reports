defmodule DailyReports.Repo.Migrations.BaseTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"
    # Create users table
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"), null: false
      add :name, :string
      add :email, :string, null: false
      add :password_hash, :string
      add :role, :string, comment: "Collaborator, Master, Manager"
      add :is_active, :boolean, default: true
      add :created_by, references(:users, type: :uuid, on_delete: :nothing)
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:is_active])

    # Create projects table
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"), null: false
      add :identifier, :string, null: false, comment: "VO-2026-01: Sigla-Ano-ID"
      add :name, :string
      add :description, :text
      add :is_active, :boolean, default: true
      add :parent_id, references(:projects, type: :uuid, on_delete: :nothing)
      add :deactivated_at, :utc_datetime
      add :deactivated_by, references(:users, type: :uuid, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:projects, [:identifier])
    create index(:projects, [:parent_id])
    create index(:projects, [:is_active])

    # Create members table
    create table(:members, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"), null: false
      add :project_id, references(:projects, type: :uuid, on_delete: :nothing), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :nothing), null: false
      add :role, :string, comment: "Owner, Admin, Developer, Viewer"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:members, [:project_id, :user_id])
    create index(:members, [:user_id])

    # Create reports table
    create table(:reports, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()"), null: false
      add :project_id, references(:projects, type: :uuid, on_delete: :nothing), null: false
      add :created_by_id, references(:members, type: :uuid, on_delete: :nothing), null: false
      add :title, :string
      add :report_date, :date, default: fragment("CURRENT_DATE")
      add :summary, :text
      add :achievements, :text
      add :impediments, :text
      add :next_steps, :text

      timestamps(type: :utc_datetime)
    end

    create index(:reports, [:project_id])
    create index(:reports, [:report_date])
    create index(:reports, [:created_by_id])
  end
end
