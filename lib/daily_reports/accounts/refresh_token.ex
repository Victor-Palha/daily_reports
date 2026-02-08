defmodule DailyReports.Accounts.RefreshToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "refresh_tokens" do
    field :token, :string
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :user, DailyReports.Accounts.User, foreign_key: :user_id, references: :id

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:token, :expires_at, :revoked_at])
    |> validate_required([:token, :expires_at])
    |> unique_constraint(:token)
    |> validate_not_expired()
  end

  @doc """
  Creates a changeset for a new refresh token.
  """
  def create_changeset(refresh_token, user, token, ttl_days \\ 30) do
    expires_at = DateTime.utc_now() |> DateTime.add(ttl_days * 24 * 60 * 60, :second)

    refresh_token
    |> cast(%{token: token, expires_at: expires_at}, [:token, :expires_at])
    |> put_assoc(:user, user)
    |> validate_required([:token, :expires_at])
    |> unique_constraint(:token)
  end

  @doc """
  Revokes the refresh token.
  """
  def revoke_changeset(refresh_token) do
    change(refresh_token, revoked_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Returns whether the refresh token is valid (not expired and not revoked).
  """
  def valid?(refresh_token) do
    !expired?(refresh_token) && !revoked?(refresh_token)
  end

  @doc """
  Returns whether the refresh token has expired.
  """
  def expired?(refresh_token) do
    DateTime.compare(refresh_token.expires_at, DateTime.utc_now()) == :lt
  end

  @doc """
  Returns whether the refresh token has been revoked.
  """
  def revoked?(refresh_token) do
    !is_nil(refresh_token.revoked_at)
  end

  defp validate_not_expired(changeset) do
    expires_at = get_field(changeset, :expires_at)

    if expires_at && DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
      add_error(changeset, :expires_at, "token has expired")
    else
      changeset
    end
  end
end
