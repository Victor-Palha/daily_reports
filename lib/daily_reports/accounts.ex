defmodule DailyReports.Accounts do
  @moduledoc """
  The Accounts context for user authentication and management.
  """

  import Ecto.Query, warn: false
  alias DailyReports.Repo
  alias DailyReports.Accounts.{User, RefreshToken, Guardian}

  ## User functions

  @doc """
  Gets a single user by ID.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user(user_id)
      %User{}

      iex> get_user(invalid_id)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user by email.

  Returns `nil` if the User does not exist.

  ## Examples

      iex> get_user_by_email("user@example.com")
      %User{}

      iex> get_user_by_email("nonexistent@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{email: "user@example.com", password: "password123"})
      {:ok, %User{}}

      iex> create_user(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{name: "New Name"})
      {:ok, %User{}}

      iex> update_user(user, %{email: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  ## Authentication functions

  @doc """
  Authenticates a user by email and password.

  Returns `{:ok, user}` if the credentials are valid, `{:error, :invalid_credentials}` otherwise.

  ## Examples

      iex> authenticate_user("user@example.com", "correct_password")
      {:ok, %User{}}

      iex> authenticate_user("user@example.com", "wrong_password")
      {:error, :invalid_credentials}

  """
  def authenticate_user(email, password) when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    cond do
      user && user.is_active && User.valid_password?(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Perform a dummy check to prevent timing attacks
        User.valid_password?(%User{}, "")
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Generates access and refresh tokens for a user.

  Returns `{:ok, access_token, refresh_token}` or `{:error, reason}`.

  ## Examples

      iex> generate_tokens(user)
      {:ok, "eyJhbGc...", "eyJhbGc..."}

  """
  def generate_tokens(%User{} = user, access_ttl \\ {1, :hour}, refresh_ttl_days \\ 30) do
    with {:ok, access_token, _claims} <-
           Guardian.encode_and_sign(user, %{}, token_type: "access", ttl: access_ttl),
         {:ok, refresh_token, _refresh_claims} <-
           Guardian.encode_and_sign(user, %{},
             token_type: "refresh",
             ttl: {refresh_ttl_days, :day}
           ),
         {:ok, _refresh_record} <- store_refresh_token(user, refresh_token, refresh_ttl_days) do
      {:ok, access_token, refresh_token}
    end
  end

  @doc """
  Refreshes an access token using a refresh token.

  Returns `{:ok, new_access_token, new_refresh_token}` or `{:error, reason}`.

  ## Examples

      iex> refresh_tokens("eyJhbGc...")
      {:ok, "new_access_token", "new_refresh_token"}

  """
  def refresh_tokens(refresh_token) when is_binary(refresh_token) do
    with {:ok, _old_claims} <-
           Guardian.decode_and_verify(refresh_token, %{"token_type" => "refresh"}),
         {:ok, user, _claims} <- Guardian.resource_from_token(refresh_token),
         refresh_record <- get_refresh_token_by_token(refresh_token),
         true <- refresh_record && RefreshToken.valid?(refresh_record),
         {:ok, _} <- revoke_refresh_token(refresh_record),
         {:ok, new_access_token, new_refresh_token} <- generate_tokens(user) do
      {:ok, new_access_token, new_refresh_token}
    else
      false -> {:error, :invalid_refresh_token}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :invalid_refresh_token}
    end
  end

  @doc """
  Revokes a refresh token.

  ## Examples

      iex> revoke_refresh_token(refresh_token)
      {:ok, %RefreshToken{}}

  """
  def revoke_refresh_token(%RefreshToken{} = refresh_token) do
    refresh_token
    |> RefreshToken.revoke_changeset()
    |> Repo.update()
  end

  @doc """
  Revokes all refresh tokens for a user.

  ## Examples

      iex> revoke_all_user_tokens(user)
      {5, nil}

  """
  def revoke_all_user_tokens(%User{id: user_id}) do
    now = DateTime.utc_now()

    from(rt in RefreshToken,
      where: rt.user_id == ^user_id and is_nil(rt.revoked_at)
    )
    |> Repo.update_all(set: [revoked_at: now])
  end

  @doc """
  Verifies an access token.

  Returns `{:ok, user, claims}` or `{:error, reason}`.

  ## Examples

      iex> verify_token("eyJhbGc...")
      {:ok, %User{}, %{"sub" => "user_id"}}

  """
  def verify_token(token) when is_binary(token) do
    with {:ok, claims} <- Guardian.decode_and_verify(token, %{"token_type" => "access"}),
         {:ok, user} <- Guardian.resource_from_claims(claims) do
      {:ok, user, claims}
    end
  end

  ## Private functions

  defp store_refresh_token(user, token, ttl_days) do
    %RefreshToken{}
    |> RefreshToken.create_changeset(user, token, ttl_days)
    |> Repo.insert()
  end

  defp get_refresh_token_by_token(token) do
    Repo.get_by(RefreshToken, token: token)
  end

  @doc """
  Cleans up expired refresh tokens.

  Returns `{count, nil}` where count is the number of deleted tokens.

  ## Examples

      iex> cleanup_expired_tokens()
      {10, nil}

  """
  def cleanup_expired_tokens do
    now = DateTime.utc_now()

    from(rt in RefreshToken,
      where: rt.expires_at < ^now
    )
    |> Repo.delete_all()
  end
end
