defmodule DailyReports.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :name, :string
    field :email, :string
    field :password_hash, :string
    field :role, :string
    field :is_active, :boolean, default: true
    field :deleted_at, :utc_datetime

    field :password, :string, virtual: true

    belongs_to :created_by_user, __MODULE__, foreign_key: :created_by, references: :id

    has_many :created_users, __MODULE__, foreign_key: :created_by
    has_many :members, DailyReports.Projects.Member, foreign_key: :user_id
    has_many :projects, through: [:members, :project]
    has_many :deactivated_projects, DailyReports.Projects.Project, foreign_key: :deactivated_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role, :is_active, :deleted_at])
    |> validate_required([:email])
    |> validate_email()
    |> validate_role()
    |> unique_constraint(:email)
    |> maybe_hash_password()
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :role])
    |> validate_required([:email, :password])
    |> validate_email()
    |> validate_password()
    |> validate_role()
    |> unique_constraint(:email)
    |> maybe_hash_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 72)
  end

  defp validate_role(changeset) do
    validate_inclusion(changeset, :role, ["Collaborator", "Master", "Manager"],
      message: "must be one of: Collaborator, Master, Manager"
    )
  end

  @doc """
  Verifies the password against the stored hash.

  Returns true if the password matches, false otherwise.
  """
  def valid_password?(%__MODULE__{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, password_hash)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password do
      changeset
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
